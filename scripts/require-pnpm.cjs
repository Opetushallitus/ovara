if (!process.env.npm_config_user_agent?.startsWith("pnpm/")) {
  console.error(
    "Use pnpm install to install dependencies. Run corepack enable to activate the pinned pnpm version.",
  );
  process.exit(1);
}
