# App Store Connect resubmission note

Apple rejected version 1.0.8 on May 29, 2026 for Guideline 3.1.2 because the App Store metadata did not include a functional Terms of Use (EULA) link for auto-renewable subscriptions.

Add this block to the bottom of the App Store Connect app description before resubmitting:

```text
Premium subscriptions unlock access to the handstand training program and premium practice content.

Available subscription plans:
- Monthly Premium
- Quarterly Premium
- Semiannual Premium
- Yearly Premium

Payment will be charged to your Apple Account at confirmation of purchase. Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. You can manage or cancel your subscription in your Apple Account settings.

Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

If App Store Connect already has the rejected binary attached, this metadata-only issue can usually be fixed by editing the app description and resubmitting the same app version. If uploading a new binary, use build 18 or later for version 1.0.8.
