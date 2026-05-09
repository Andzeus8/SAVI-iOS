# SAVI PostHog Dashboard Plan

PostHog should be used for founder/investor product dashboards, not private-library surveillance.

## Dashboards

1. **Executive Pulse**
   - DAU, WAU, MAU
   - D1, D7, D30 retention
   - average session duration
   - app version/build adoption

2. **Activation Funnel**
   - app opened
   - onboarding completed
   - Share Sheet setup opened
   - first save completed
   - first search performed
   - first folder selected or created

3. **Saving Reliability**
   - saves per user
   - share extension opened
   - save completed vs failed
   - metadata success vs failure
   - top failure reasons

4. **Search And Organization**
   - searches per active user
   - result-count distribution
   - folder creation/selection
   - source groups that drive saves

5. **Social Readiness**
   - public links published
   - feed viewed
   - friend added
   - like added
   - friend link saved
   - reports and blocks

6. **Public Link Trends**
   - top public domains
   - top public canonical URLs
   - trending public links
   - metadata failures by domain

## PostHog Product Settings

- Start with manual event capture only.
- Keep autocapture off.
- Keep session replay off.
- Do not enable surveys or feature flags that collect free-form private text until privacy copy is updated.
- Identify users only after account creation; before that use an anonymous install/session id.

## Setup Values Needed Later

Provide only:

- PostHog host,
- PostHog project token.

Do not provide passwords, personal account credentials, or unrelated admin secrets.
