import { test, expect } from '@playwright/test';

test.describe('Authentication Flow', () => {
  test('user can sign up and see dashboard', async ({ page, request }) => {
    const email = `e2e-${Date.now()}@test.duin.home`;
    const password = 'E2eTestPass123!';

    await page.goto('/signup');
    await page.fill('[name="email"]', email);
    await page.fill('[name="password"]', password);
    await page.click('button[type="submit"]');
    await expect(page).toHaveURL(/\/(dashboard|home)/, { timeout: 10_000 });

    const serviceKey = process.env.TEST_SERVICE_KEY;
    if (serviceKey) {
      try {
        const tokenResp = await request.post(
          `${process.env.API_URL}/auth/v1/token?grant_type=password`,
          {
            headers: { apikey: process.env.SUPABASE_ANON_KEY ?? '' },
            data: { email, password },
          }
        );
        const { user } = await tokenResp.json();
        if (user?.id) {
          await request.delete(
            `${process.env.API_URL}/auth/v1/admin/users/${user.id}`,
            {
              headers: {
                apikey: serviceKey,
                Authorization: `Bearer ${serviceKey}`,
              },
            }
          );
        }
      } catch {
        console.warn('E2E signup test: cleanup failed (non-fatal)');
      }
    }
  });

  test('user can log in with existing credentials', async ({ page }) => {
    const email = process.env.TEST_USER_EMAIL;
    const password = process.env.TEST_USER_PASSWORD;
    if (!email || !password) {
      test.skip(true, 'TEST_USER_EMAIL / TEST_USER_PASSWORD not set — skipping login test');
    }
    await page.goto('/login');
    await page.fill('[name="email"]', email!);
    await page.fill('[name="password"]', password!);
    await page.click('button[type="submit"]');
    await expect(page).toHaveURL(/\/(dashboard|home)/, { timeout: 10_000 });
  });

  test('invalid login shows error message', async ({ page }) => {
    await page.goto('/login');
    await page.fill('[name="email"]', 'nonexistent@test.duin.home');
    await page.fill('[name="password"]', 'WrongPassword!');
    await page.click('button[type="submit"]');
    await expect(page.locator('[role="alert"], .error, .toast')).toBeVisible({ timeout: 5_000 });
  });
});
