# LLM Guidelines for NeetoSign API Docs

## Important Rules

1. **Never make direct changes to the `bundled` folder.** The `bundled` folder is auto-generated and should not be edited manually.

2. **Always make changes in the `docs` folder.** All source content lives in the `docs` folder. This is where edits should be made.

3. **After making any changes, run `yarn build:dev`.** This regenerates the API documentation in the `bundled` folder from the `docs` folder.

4. **Both `docs` and `bundled` changes must be committed and pushed.** After running `yarn build:dev`, the updated files in both the `docs` folder and the `bundled` folder need to be checked in and pushed together.
