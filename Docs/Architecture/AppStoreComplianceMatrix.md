# SAVI App Store Compliance Matrix

This matrix maps Apple-facing requirements to SAVI product work. Status values:
`Ready`, `Blocked`, `Not Started`, or `Not Needed For Current Release`.

## Current Release Assumption

Current TestFlight/App Store candidate is private-save-first with social hidden
and no live Supabase/PostHog production collection unless explicitly enabled
later.

| Area | SAVI Requirement | Status | Notes |
|---|---|---:|---|
| Privacy Policy | Public URL in App Store Connect and in app | Blocked | Founder must provide final URL/copy before full App Store |
| App Privacy Labels | Match exact final data collection | Blocked | Current answer packet: `Docs/Architecture/Runbooks/AppStorePrivacyLabels.md`; update when analytics/accounts/sync change; inventory: `Docs/Architecture/PrivacyDataInventory.md` |
| Required Reason APIs | Privacy manifest covers used APIs | Ready | Current manifests declare FileTimestamp `C617.1` and app UserDefaults `CA92.1`; audit: `Docs/Architecture/PrivacyManifestAudit.md` |
| Export Compliance | Answer matches encryption behavior | Blocked | Founder/legal confirmation required; current technical packet: `Docs/Architecture/Runbooks/AppStoreExportCompliance.md`; rerun `scripts/savi-appstore-export-compliance-check.py` after SDK/network/security/encryption changes |
| Support Contact | Public support URL/email | Ready | Current beta email: `1080solutionsA@gmail.com` |
| Feedback | TestFlight feedback path | Ready | Profile/help path and App Store Connect email documented |
| Age Rating | App Store Connect age questionnaire | Blocked | Founder/legal must answer in ASC; current answer packet: `Docs/Architecture/Runbooks/AppStoreAgeRating.md`; rerun `scripts/savi-appstore-age-rating-check.py` after sample/social/browser/health changes |
| Sample Content | Safe, removable, non-misleading | Ready | Current review: `Docs/Architecture/SampleContentReview.md`; rerun `scripts/savi-sample-content-check.py` after sample changes |
| Health Claims | No medical advice/treatment claims | Ready | Current samples use research/questions-for-doctor framing and NCI counterbalance; rerun sample-content check before App Store |
| Accounts | Sign in with Apple if account auth ships | Not Needed For Current Release | Required when accounts/social/sync launch |
| Account Deletion | In-app deletion of account and data | Not Needed For Current Release | Required before accounts launch; runbook: `Docs/Backend/AccountDeletionRunbook.md` |
| Sign in Token Revocation | Revoke Apple tokens on deletion | Not Needed For Current Release | Required with Sign in with Apple; covered by account deletion runbook |
| Social / UGC | Filtering/moderation/report/block/contact | Not Needed For Current Release | Required before public social |
| Public Publishing | Explicit user action only | Not Needed For Current Release | Required before social/public links |
| Delete / Unpublish | Users can remove public content | Not Needed For Current Release | Required before social/public links |
| Notifications | Permission prompt, settings, privacy-safe notification text | Not Needed For Current Release | Required before APNs/push launches; runbook: `Docs/Backend/NotificationRunbook.md` |
| Private Vault | Hidden until unlocked; never public | In progress | Keep out of analytics/social/sync |
| Analytics | Manual allowlist + opt-in/copy | Not Needed For Current Release | Required before PostHog goes live |
| Tracking / ATT | No ad tracking/data broker use | Ready | Revisit if marketing/ad SDKs are added |
| CloudKit / iCloud | Only private backup if enabled | Not Needed For Current Release | Keep no-op/hidden until entitlements verified |
| Third-Party SDKs | Disclose SDK data practices | Ready | Current repo has no linked third-party SDKs; inventory: `Docs/Architecture/ThirdPartySDKInventory.md` |
| App Review Notes | Explain samples, social hidden, share extension | In progress | Finalize per submitted build |
| Real Device QA | App and share extension on physical iPhone | In progress | Required before App Store submission |

## Changes That Trigger Re-review

Update this matrix when adding:

- accounts,
- Supabase,
- PostHog,
- CloudKit/iCloud backup,
- public publishing,
- friend feeds,
- push notifications,
- private file sync,
- in-app purchases,
- health integrations,
- sample library health/media/private-document content,
- location,
- contacts,
- ads or marketing SDKs.
