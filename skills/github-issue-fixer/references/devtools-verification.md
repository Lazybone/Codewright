# Browser Verification with MCP Google DevTools

When an issue involves a visual problem, a frontend bug, or browser-specific
behavior, use MCP Google DevTools for verification.

## When to Use Browser Verification

Use DevTools when the issue involves one of these topics:
- Layout/CSS problems (elements incorrectly positioned, missing styles)
- JavaScript errors in the browser console
- Network requests that fail (API calls, asset loading)
- Interaction bugs (click handlers, forms, navigation)
- Responsive design problems
- Performance problems (slow rendering, memory leaks)

## Procedure

### 1. Start Dev Server

Make sure the application is running locally:
```bash
# Detect the start command from package.json, Makefile, etc.
npm run dev    # or yarn dev, pnpm dev
python manage.py runserver
cargo run
```

Wait until the server is ready and note the URL (usually http://localhost:3000
or http://localhost:8080).

### 2. Open Page in Browser

Use MCP Google DevTools to:
- Open the relevant page
- Navigate to the affected area
- Perform the reproduction steps from the issue

### 3. Before the Fix: Document the Bug

Check and document:
- **Console**: JavaScript errors or warnings
- **Network**: Failed requests (4xx, 5xx, CORS)
- **Elements**: DOM structure and computed styles
- **Screenshots**: Capture the visual state

### 4. After the Fix: Verification

Reload the page and repeat the reproduction steps:
- Bug should no longer occur
- No new console errors
- No new failed network requests
- Visual result matches the expected behavior

### 5. Document the Result

```
## Browser Verification

### Before
- Console errors: <yes/no, which ones>
- Visual problem: <description>
- Network errors: <yes/no, which ones>

### After
- Console errors: <fixed/no new ones>
- Visual result: <correct/description>
- Network status: <all requests successful>

### Conclusion
Bug fixed: yes/no
New problems: yes/no
```

## Fallback Without MCP DevTools

If MCP Google DevTools is not available:
1. Inform the user that manual browser tests are recommended
2. Describe the exact steps the user should perform in the browser
3. Rely on the automated tests as the primary verification
