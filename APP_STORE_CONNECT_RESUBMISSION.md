# App Store Connect resubmission note

Apple rejected version 1.0.8 on May 29, 2026 for Guideline 3.1.2 because the App Store metadata did not include a functional Terms of Use (EULA) link for auto-renewable subscriptions.

The updated binary is version 1.0.9 build 20. Its Premium screen includes
functional Privacy Policy and Terms of Use links.

Before resubmitting:

1. Upload the new IPA.
2. Set the App Store Connect Privacy Policy URL to:
   `https://banana-57559.web.app/privacy-policy.html`
3. Add this block to the bottom of the App Store Connect app description:

```text
Premium subscriptions unlock access to the handstand training program and premium practice content.

Available subscription plans:
- Monthly Premium
- Quarterly Premium
- Semiannual Premium
- Yearly Premium

Payment will be charged to your Apple Account at confirmation of purchase. Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. You can manage or cancel your subscription in your Apple Account settings.

Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://banana-57559.web.app/privacy-policy.html
```

4. Confirm that the four auto-renewable subscription products are attached to
   the submitted version and available for App Review.
