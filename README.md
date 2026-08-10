# NeetoSign API Docs

This repository contains the documentation for the [NeetoSign APIs](https://apidocs.neetosign.com/getting-started/introduction), built using [Mintlify](https://mintlify.com/).

## Development Setup

1. ### Install Mintlify CLI globally

   ```bash
   npm i -g mint
   ```

2. ### Install project dependencies

   ```bash
   yarn install
   ```

3. ### Make code changes in docs folder

4. ### Preview the changes

   ```bash
   yarn docs:preview
   ```

   A local preview will be available at `http://localhost:3000`. You can customize the port using the `--port` flag:

   ```bash
   yarn docs:preview --port 3333
   ```

   DO NOT MAKE CODE CHANGES IN BUNDLED FOLDER.

5. ### Build the API

   After making code changes you must run `yarn build:dev`. This will make changes in the `bundled` folder which is what mintlify uses.
   You should NEVER make changes to the `bundled` folder directly.

   Refer to [llm.md](llm.md) for more info.
