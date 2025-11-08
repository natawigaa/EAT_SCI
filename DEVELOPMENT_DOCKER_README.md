This project includes example Docker artifacts to help local development and simple deployments.

Files added
- `functions/clear_manual_overrides/Dockerfile`  — Deno-based image for the function in `functions/clear_manual_overrides`.
- `docker-compose.yml` — simple local stack: Postgres (not a full Supabase suite), the Deno function, and an nginx web preview for Flutter Web.

Why this exists
- The Dockerfile lets you run the `clear_manual_overrides` function as a container (for local dev or deploy to Cloud Run / other container runtimes).
- The docker-compose file shows a minimal local environment that lets you:
  - run a Postgres database locally
  - run the function container (it depends on db)
  - preview a Flutter Web build served by nginx (you must run `flutter build web` first)

Important caveats
- This compose is intentionally minimal. It is NOT a full Supabase local environment. Supabase has several services (auth, realtime, storage, functions) and the full local stack is best run with the `supabase` CLI which will set up many containers and wiring for you.
- The `db` service is plain Postgres. If your functions rely on Supabase-specific extensions or schema, you should either use the Supabase local tooling or import the right SQL/migrations.

How to use (local dev)
1. Build your Flutter web assets (if you want to use the `web` service):

```powershell
# from repo root
flutter build web --release
```

2. Build and start the compose stack:

```powershell
# from repo root
docker compose up --build
```

3. Services:
- Postgres: exposed on localhost:5432
- Function: http://localhost:8000 (the Deno `serve` will listen on the PORT env if set)
- Web preview: http://localhost:8080 (serves ./build/web)

4. To stop the stack:

```powershell
docker compose down
```

Deploying the function image
- Build and push the image to your registry (Docker Hub, GHCR, GCR, etc):

```powershell
# Example: build locally
docker build -t yourrepo/clear-manual-overrides:latest ./functions/clear_manual_overrides
# push to registry
docker push yourrepo/clear-manual-overrides:latest
```

- Then deploy the image to your container hosting (Cloud Run, ECS, DigitalOcean App Platform, Kubernetes). Provide the environment variables `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` at runtime.

What does "host web" mean?
- "Host web" simply means running your built web files (static HTML/CSS/JS) on a server so others can access them via HTTP. In this repo the Flutter Web build produces static files in `build/web`. Serving them ("hosting") can be done many ways:
  - Use a static host (Netlify, Vercel) — easy, no infra
  - Upload to S3 + CloudFront — scalable
  - Use a small container (nginx) to serve the files — good for quick self-hosting or when you want to bundle with other services (example in docker-compose)

If you want, I can:
- Replace the minimal Postgres with a full Supabase local compose (using supabase images) and add an example of applying the repo's migrations.
- Add a GitHub Actions workflow to build the function image and optionally push it to GHCR.
- Implement MediaStore-based download to write Excel to public Downloads (Android) if you prefer.

Tell me which follow-up you'd like (e.g. "Add GH Action for function image" or "Use supabase/local compose example").
