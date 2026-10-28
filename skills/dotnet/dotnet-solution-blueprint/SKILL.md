---
name: dotnet-solution-blueprint
description: Opinionated blueprint for production-grade .NET / ASP.NET Core solutions - solution layout (Clean Architecture or Vertical Slices), Program.cs wiring, options/config, EF Core + Dapper, validation, ProblemDetails errors, auth (JWT/OIDC + policies), Serilog + OpenTelemetry, health checks, rate limiting, background jobs, testing (xUnit, WebApplicationFactory, Testcontainers), Docker and GitHub Actions. Use when creating a new .NET project, adding a module/feature to one, or reviewing a .NET codebase structure.
---

# .NET Solution Blueprint

Use with `core/my-engineering-style`. For deep topics, defer to the focused skills:
`dotnet/dotnet-webapi`, `dotnet/efcore-patterns`, `dotnet/optimizing-ef-core-queries`,
`dotnet/modern-csharp-coding-standards`, `dotnet/microsoft-extensions-configuration`, `dotnet/dependency-injection-patterns`, `dotnet/testcontainers-integration-tests`,
`database/sql-server-expert`, `database/sqlite-expert`.

## 1. Solution layout

### Option A — Clean Architecture (default for business systems)

```
MyApp.sln
Directory.Build.props        # shared: TargetFramework, Nullable, TreatWarningsAsErrors, analyzers
Directory.Packages.props     # Central Package Management (versions in one place)
.editorconfig  global.json  README.md  AGENTS.md
src/
  MyApp.Domain/              # entities, value objects, domain events, rules. NO dependencies.
  MyApp.Application/         # use cases (commands/queries), DTOs, validators, interfaces (ports)
  MyApp.Infrastructure/      # EF Core DbContext, migrations, repos, email/SMS/files, external APIs
  MyApp.Api/                 # ASP.NET Core host: endpoints, auth, middleware, DI composition root
  MyApp.Web/ (optional)      # Blazor / MVC / SPA host
tests/
  MyApp.Domain.Tests/
  MyApp.Application.Tests/
  MyApp.Api.IntegrationTests/   # WebApplicationFactory + Testcontainers
deploy/  docker/  .github/workflows/
```

Dependency rule: `Api → Application → Domain`, `Infrastructure → Application/Domain`. Domain references nothing.

### Option B — Vertical Slices (great for API-heavy or fast-moving apps)

```
src/MyApp.Api/
  Features/
    Orders/
      CreateOrder.cs     # request, validator, handler, endpoint mapping — all in one file
      GetOrder.cs
      OrdersModule.cs    # MapGroup("/api/v1/orders")
  Infrastructure/  Common/  Program.cs
```

Pick one per solution and record it in an ADR.

## 2. Directory.Build.props

```xml
<Project>
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <AnalysisLevel>latest-recommended</AnalysisLevel>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
    <InvariantGlobalization>false</InvariantGlobalization> <!-- keep false if Arabic culture formatting is needed -->
  </PropertyGroup>
</Project>
```

Use the current LTS/STS the project targets; check `global.json`.

## 3. Program.cs skeleton (Minimal APIs)

```csharp
var builder = WebApplication.CreateBuilder(args);

// ---- Logging & telemetry
builder.Host.UseSerilog((ctx, lc) => lc.ReadFrom.Configuration(ctx.Configuration).Enrich.FromLogContext());
builder.Services.AddOpenTelemetry()
    .WithTracing(t => t.AddAspNetCoreInstrumentation().AddHttpClientInstrumentation().AddOtlpExporter())
    .WithMetrics(m => m.AddAspNetCoreInstrumentation().AddRuntimeInstrumentation().AddOtlpExporter());

// ---- Options (validated at startup)
builder.Services.AddOptions<SmtpOptions>()
    .BindConfiguration(SmtpOptions.Section)
    .ValidateDataAnnotations()
    .ValidateOnStart();

// ---- Data
builder.Services.AddDbContext<AppDbContext>(o =>
    o.UseSqlServer(builder.Configuration.GetConnectionString("Default"),
                   sql => sql.EnableRetryOnFailure()));

// ---- App services
builder.Services.AddApplication();       // extension in Application project
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddValidatorsFromAssemblyContaining<CreateOrderValidator>();

// ---- Errors
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();

// ---- Security
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o => builder.Configuration.Bind("Auth:Jwt", o));
builder.Services.AddAuthorizationBuilder()
    .SetFallbackPolicy(new AuthorizationPolicyBuilder().RequireAuthenticatedUser().Build()) // deny by default
    .AddPolicy("orders:approve", p => p.RequireClaim("permission", "orders:approve"));
builder.Services.AddRateLimiter(o =>
{
    o.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    o.AddFixedWindowLimiter("default", l => { l.PermitLimit = 100; l.Window = TimeSpan.FromMinutes(1); });
});
builder.Services.AddCors(o => o.AddPolicy("spa", p =>
    p.WithOrigins(builder.Configuration.GetSection("Cors:Origins").Get<string[]>()!)
     .AllowAnyHeader().AllowAnyMethod()));

// ---- API docs & health
builder.Services.AddOpenApi();
builder.Services.AddHealthChecks().AddDbContextCheck<AppDbContext>("db", tags: ["ready"]);

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages();
if (!app.Environment.IsDevelopment()) app.UseHsts();
app.UseHttpsRedirection();
app.UseSecurityHeaders();            // CSP, X-Content-Type-Options, Referrer-Policy, frame-ancestors
app.UseSerilogRequestLogging();
app.UseCors("spa");
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();

if (app.Environment.IsDevelopment()) app.MapOpenApi();
app.MapHealthChecks("/health/live", new() { Predicate = _ => false }).AllowAnonymous();
app.MapHealthChecks("/health/ready", new() { Predicate = c => c.Tags.Contains("ready") }).AllowAnonymous();

app.MapGroup("/api/v1").RequireRateLimiting("default").MapOrders();

app.Run();

public partial class Program;  // for WebApplicationFactory
```

## 4. Endpoint pattern

```csharp
public static class OrdersEndpoints
{
    public static RouteGroupBuilder MapOrders(this RouteGroupBuilder api)
    {
        var g = api.MapGroup("/orders").WithTags("Orders");

        g.MapGet("/{id:int}", async Task<Results<Ok<OrderDto>, NotFound>> (int id, IOrderQueries q, CancellationToken ct)
            => await q.GetAsync(id, ct) is { } dto ? TypedResults.Ok(dto) : TypedResults.NotFound());

        g.MapPost("/", async Task<Results<Created<OrderDto>, ValidationProblem>> (
                CreateOrderRequest req, IValidator<CreateOrderRequest> v, IOrderService s, CancellationToken ct) =>
            {
                var r = await v.ValidateAsync(req, ct);
                if (!r.IsValid) return TypedResults.ValidationProblem(r.ToDictionary());
                var dto = await s.CreateAsync(req, ct);
                return TypedResults.Created($"/api/v1/orders/{dto.Id}", dto);
            });

        g.MapPost("/{id:int}/approve", ApproveAsync).RequireAuthorization("orders:approve");
        return g;
    }
}
```

Rules: typed results, `CancellationToken` everywhere, DTOs (records) — never entities, validation at the edge,
authorization on every endpoint (fallback policy covers forgotten ones).

## 5. Error handling

```csharp
internal sealed class GlobalExceptionHandler(ILogger<GlobalExceptionHandler> log, IProblemDetailsService pds) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext ctx, Exception ex, CancellationToken ct)
    {
        var (status, title) = ex switch
        {
            NotFoundException       => (404, "Resource not found"),
            ConflictException or DbUpdateConcurrencyException => (409, "Conflict"),
            DomainRuleException     => (422, "Business rule violated"),
            UnauthorizedAccessException => (403, "Forbidden"),
            _                       => (500, "An unexpected error occurred")
        };
        if (status == 500) log.LogError(ex, "Unhandled exception");
        ctx.Response.StatusCode = status;
        return await pds.TryWriteAsync(new()
        {
            HttpContext = ctx,
            ProblemDetails = { Status = status, Title = title,
                               Detail = status == 500 ? null : ex.Message }   // never leak internals on 500
        });
    }
}
```

## 6. Data access

- `AppDbContext` with `ApplyConfigurationsFromAssembly`; one `IEntityTypeConfiguration<T>` per entity.
- Auditing via `SaveChangesInterceptor` (CreatedAtUtc/By, UpdatedAtUtc/By); soft delete via global query filter.
- Reads: `AsNoTracking()` + projection to DTO with `Select`. Writes: load aggregate, mutate via methods, `SaveChangesAsync`.
- Bulk: `ExecuteUpdateAsync` / `ExecuteDeleteAsync`. Heavy reports: Dapper with parameterized SQL.
- Concurrency: `RowVersion` (`[Timestamp]`) on SQL Server; version column on SQLite.
- Migrations: `dotnet ef migrations add <Name> -p src/MyApp.Infrastructure -s src/MyApp.Api`;
  deploy via migration bundle (`dotnet ef migrations bundle`) or idempotent script (`--idempotent`), not `Database.Migrate()` on app start in multi-instance prod.
- Outbox table for reliable domain events/integration messages.

## 7. Background work

- `BackgroundService` for simple loops (always respect `stoppingToken`, catch & log per iteration).
- Hangfire / Quartz.NET for scheduled & persistent jobs (dashboard behind admin auth).
- `Channel<T>` for in-process queues. Idempotent handlers; retries with Polly (`Microsoft.Extensions.Http.Resilience`).

## 8. HTTP clients

```csharp
builder.Services.AddHttpClient<IPaymentGateway, PaymentGatewayClient>(c =>
{
    c.BaseAddress = new Uri(builder.Configuration["Payments:BaseUrl"]!);
    c.Timeout = TimeSpan.FromSeconds(30);
}).AddStandardResilienceHandler();   // retry + circuit breaker + timeout
```

Never `new HttpClient()` per call.

## 9. Testing

- Unit: xUnit + FluentAssertions/Shouldly; test domain & handlers without the DB.
- Integration: `WebApplicationFactory<Program>` + **Testcontainers.MsSql** (real SQL Server); reset with Respawn.
- Auth in tests: a test auth handler that issues claims per test.
- Snapshot API responses (Verify) for contract stability.
- `dotnet test --collect:"XPlat Code Coverage"` in CI.

## 10. Docker

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore src/MyApp.Api/MyApp.Api.csproj
RUN dotnet publish src/MyApp.Api/MyApp.Api.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app .
USER $APP_UID                      # non-root
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "MyApp.Api.dll"]
```

Or `dotnet publish /t:PublishContainer` (see `dotnet/sdk-container-publishing`).

## 11. GitHub Actions (CI)

```yaml
name: ci
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with: { global-json-file: global.json }
      - run: dotnet restore
      - run: dotnet build --no-restore -c Release
      - run: dotnet test --no-build -c Release --collect:"XPlat Code Coverage"
      - run: dotnet list package --vulnerable --include-transitive
      - run: dotnet format --verify-no-changes
```

## 12. New-feature checklist

- [ ] Request/response DTOs + validator
- [ ] Handler/service with business rules in Domain
- [ ] Endpoint with auth policy, typed results, OpenAPI metadata
- [ ] EF configuration + migration (+ indexes)
- [ ] Unit tests + integration test (happy path + validation + auth + not found + conflict)
- [ ] Logs with useful context; no PII
- [ ] `.http` file or OpenAPI updated; README if config changed
