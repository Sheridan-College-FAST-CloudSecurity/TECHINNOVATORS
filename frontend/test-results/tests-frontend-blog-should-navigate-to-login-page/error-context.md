# Test info

- Name: should navigate to login page
- Location: /workspaces/TECHINNOVATORS/frontend/tests-frontend/blog.spec.js:8:1

# Error details

```
Error: locator.click: Test timeout of 30000ms exceeded.
Call log:
  - waiting for getByRole('link', { name: 'Login' })

    at /workspaces/TECHINNOVATORS/frontend/tests-frontend/blog.spec.js:10:51
```

# Page snapshot

```yaml
- main:
  - heading "You are about to access a development port served by someone's codespace" [level=2]
  - list:
    - listitem:
      - group:
        - button "Only continue to visit the website if you trust whoever sent you the link"
    - listitem:
      - paragraph: Personal information you disclose such as credit card numbers or passwords may be available to the developer of this site
      - paragraph: Note that this warning will only be shown once per codespace session.
  - link "Report unsafe page":
    - /url: https://support.github.com/contact/report-abuse?category=report-abuse
  - button "Continue"
  - paragraph:
    - text: "Next: You'll be redirected to:"
    - link "psychic-waffle-5gr4jq74vjq7hvgqj-8080.app.github.dev":
      - /url: "#"
- contentinfo:
  - heading "Footer" [level=2]
  - link "Homepage":
    - /url: https://github.com
  - text: © 2025 GitHub, Inc.
  - navigation "Footer":
    - heading "Footer navigation" [level=3]
    - list "Footer navigation":
      - listitem:
        - link "Terms":
          - /url: https://docs.github.com/site-policy/github-terms/github-terms-of-service
      - listitem:
        - link "Privacy":
          - /url: https://docs.github.com/site-policy/privacy-policies/github-privacy-statement
      - listitem:
        - link "Security":
          - /url: https://github.com/security
      - listitem:
        - link "Status":
          - /url: https://www.githubstatus.com/
      - listitem:
        - link "Docs":
          - /url: https://docs.github.com
      - listitem:
        - link "Contact GitHub":
          - /url: https://support.github.com?tags=dotcom-footer
      - listitem:
        - link "Pricing":
          - /url: https://github.com/pricing
      - listitem:
        - link "API":
          - /url: https://docs.github.com
      - listitem:
        - link "Training":
          - /url: https://services.github.com
      - listitem:
        - link "Blog":
          - /url: https://github.blog
      - listitem:
        - link "About":
          - /url: https://github.com/about
```

# Test source

```ts
   1 | const { test, expect } = require('@playwright/test');
   2 |
   3 | test('homepage should load and show BlogSphere title', async ({ page }) => {
   4 |   await page.goto('https://psychic-waffle-5gr4jq74vjq7hvgqj-8080.app.github.dev');
   5 |   await expect(page).toHaveTitle(/BlogSphere/i);
   6 | });
   7 |
   8 | test('should navigate to login page', async ({ page }) => {
   9 |   await page.goto('https://psychic-waffle-5gr4jq74vjq7hvgqj-8080.app.github.dev');
> 10 |   await page.getByRole('link', { name: 'Login' }).click(); // Adjust if you use an icon or button
     |                                                   ^ Error: locator.click: Test timeout of 30000ms exceeded.
  11 |   await expect(page).toHaveURL(/.*login.*/);
  12 | });
  13 |
```