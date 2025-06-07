const { test, expect } = require('@playwright/test');

test('homepage should load and show BlogSphere title', async ({ page }) => {
  await page.goto('https://psychic-waffle-5gr4jq74vjq7hvgqj-8080.app.github.dev');
  await expect(page).toHaveTitle(/BlogSphere/i);
});

test('should navigate to login page', async ({ page }) => {
  await page.goto('https://psychic-waffle-5gr4jq74vjq7hvgqj-8080.app.github.dev');
  await page.getByRole('link', { name: 'Login' }).click(); // Adjust if you use an icon or button
  await expect(page).toHaveURL(/.*login.*/);
});
