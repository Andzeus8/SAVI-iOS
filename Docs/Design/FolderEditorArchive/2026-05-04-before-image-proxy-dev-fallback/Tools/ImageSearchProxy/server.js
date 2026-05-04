#!/usr/bin/env node

const http = require("http");
const { URL } = require("url");

const port = Number(process.env.PORT || 8787);
const pexelsApiKey = process.env.PEXELS_API_KEY;
const maxImageBytes = 12 * 1024 * 1024;
const rateWindowMs = 60 * 1000;
const rateLimit = Number(process.env.RATE_LIMIT_PER_MINUTE || 80);
const requestsByIp = new Map();

function json(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
  });
  res.end(body);
}

function rateLimited(req) {
  const ip = req.socket.remoteAddress || "local";
  const now = Date.now();
  const bucket = requestsByIp.get(ip) || [];
  const recent = bucket.filter((timestamp) => now - timestamp < rateWindowMs);
  recent.push(now);
  requestsByIp.set(ip, recent);
  return recent.length > rateLimit;
}

function clampPerPage(value) {
  const parsed = Number(value || 24);
  if (!Number.isFinite(parsed)) return 24;
  return Math.max(1, Math.min(30, Math.floor(parsed)));
}

function saviResult(photo) {
  const src = photo.src || {};
  return {
    id: String(photo.id),
    provider: "Pexels",
    thumbURL: src.medium || src.small || src.tiny || src.large || "",
    previewURL: src.large || src.medium || src.original || "",
    downloadURL: src.large2x || src.large || src.original || src.medium || "",
    photographerName: photo.photographer || null,
    photographerURL: photo.photographer_url || null,
    sourceURL: photo.url || null,
    averageColor: photo.avg_color || null,
  };
}

async function handleSearch(req, res, url) {
  if (!pexelsApiKey) {
    json(res, 503, { error: "PEXELS_API_KEY is not configured." });
    return;
  }

  const query = (url.searchParams.get("q") || "").trim();
  if (!query) {
    json(res, 400, { error: "Missing q." });
    return;
  }

  const page = Math.max(1, Number(url.searchParams.get("page") || 1) || 1);
  const perPage = clampPerPage(url.searchParams.get("per_page"));
  const pexelsURL = new URL("https://api.pexels.com/v1/search");
  pexelsURL.searchParams.set("query", query);
  pexelsURL.searchParams.set("page", String(page));
  pexelsURL.searchParams.set("per_page", String(perPage));

  const upstream = await fetch(pexelsURL, {
    headers: { Authorization: pexelsApiKey },
  });
  const text = await upstream.text();
  if (!upstream.ok) {
    json(res, upstream.status, { error: "Pexels search failed.", details: text.slice(0, 240) });
    return;
  }

  const decoded = JSON.parse(text);
  const results = (decoded.photos || [])
    .map(saviResult)
    .filter((result) => result.thumbURL && result.previewURL && result.downloadURL);

  json(res, 200, {
    provider: "Pexels",
    page,
    perPage,
    results,
  });
}

function readJSON(req) {
  return new Promise((resolve, reject) => {
    let raw = "";
    req.on("data", (chunk) => {
      raw += chunk;
      if (raw.length > 128 * 1024) {
        reject(new Error("Request too large."));
        req.destroy();
      }
    });
    req.on("end", () => {
      try {
        resolve(JSON.parse(raw || "{}"));
      } catch (error) {
        reject(error);
      }
    });
    req.on("error", reject);
  });
}

async function handleDownload(req, res) {
  const body = await readJSON(req);
  const downloadURL = String(body.downloadURL || "");
  const parsed = new URL(downloadURL);
  if (!["images.pexels.com", "www.pexels.com"].includes(parsed.hostname)) {
    json(res, 400, { error: "Only Pexels image URLs are allowed." });
    return;
  }

  const upstream = await fetch(parsed);
  if (!upstream.ok) {
    json(res, upstream.status, { error: "Image download failed." });
    return;
  }

  const contentType = upstream.headers.get("content-type") || "image/jpeg";
  if (!contentType.startsWith("image/")) {
    json(res, 400, { error: "Downloaded resource was not an image." });
    return;
  }

  const contentLength = Number(upstream.headers.get("content-length") || 0);
  if (contentLength > maxImageBytes) {
    json(res, 413, { error: "Image is too large." });
    return;
  }

  const arrayBuffer = await upstream.arrayBuffer();
  if (arrayBuffer.byteLength > maxImageBytes) {
    json(res, 413, { error: "Image is too large." });
    return;
  }

  const base64 = Buffer.from(arrayBuffer).toString("base64");
  json(res, 200, {
    dataURL: `data:${contentType};base64,${base64}`,
  });
}

const server = http.createServer(async (req, res) => {
  try {
    if (rateLimited(req)) {
      json(res, 429, { error: "Too many requests." });
      return;
    }

    const url = new URL(req.url, `http://${req.headers.host || "localhost"}`);
    if (req.method === "GET" && url.pathname === "/health") {
      json(res, 200, { ok: true });
      return;
    }
    if (req.method === "GET" && url.pathname === "/image-search") {
      await handleSearch(req, res, url);
      return;
    }
    if (req.method === "POST" && url.pathname === "/image-download") {
      await handleDownload(req, res);
      return;
    }
    json(res, 404, { error: "Not found." });
  } catch (error) {
    json(res, 500, { error: error.message || "Unexpected server error." });
  }
});

server.listen(port, () => {
  console.log(`SAVI image search proxy listening on http://127.0.0.1:${port}`);
});
