# SAVI Image Search Proxy

Tiny development proxy for SAVI's stock-safe image picker. The iOS app talks to this service through `SAVI_IMAGE_SEARCH_BASE_URL`; the Pexels API key stays on the server.

## Run locally

```bash
export PEXELS_API_KEY="your_pexels_key"
PORT=8787 node server.js
```

Then launch the app with:

```bash
SAVI_IMAGE_SEARCH_BASE_URL=http://127.0.0.1:8787
```

## Endpoints

- `GET /image-search?q=recipes&page=1&per_page=24`
- `POST /image-download` with a selected `SaviImageSearchResult` JSON body

The proxy returns sanitized SAVI result JSON and data URLs for selected images. The app re-renders the image before saving it, which strips image metadata and keeps the existing SAVI archive/export behavior.
