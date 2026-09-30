# Sourced by test-spec-check.sh (needs T, CHECK, PASS/FAIL, new_repo, commit_at, has, hasnt, spec).
# Stack-neutral fixtures: C# ASP.NET, Angular, Java Spring, Kotlin, Rust; identifiers; NO-REVIEW.

N="$T/dotnet"; G="$T/ng"; J="$T/spring"; K="$T/kt"
new_repo "$N"; new_repo "$G"; new_repo "$J"; new_repo "$K"
mkdir -p "$N/Api/Controllers" "$N/Api/Pages" "$N/Api/Shared" "$N/tools/src" "$G/src/app/users" \
  "$J/src/main/java/com/acme" "$K/app/src/main/kotlin/com/acme"

cat > "$N/Api/Controllers/UsersController.cs" <<'EOF'
#region Users
[ApiController]
public class UsersController : ControllerBase
{
    [HttpPost("api/users/{id}/email")]
    public IActionResult ChangeEmail(Guid id) => Ok(new { AccessToken = a, RefreshToken = r });

    [HttpDelete("/api/users/{id:guid}")]
    public IActionResult Delete(Guid id) => NoContent();

    [HttpPost("{id}/avatars")]
    public IActionResult Avatars(Guid id) => Ok("avatar");
}
#endregion
EOF
cat > "$N/Api/Program.cs" <<'EOF'
var app = builder.Build();
app.MapPost("/api/sessions/refresh", (RefreshRequest r) => Results.Ok(new SessionDto(r.Token)));
public record SessionDto(string AccessToken, int ExpiresIn);
EOF
echo '<Project Sdk="Microsoft.NET.Sdk.Web" />' > "$N/Api/Api.csproj"
echo '@page' > "$N/Api/Pages/Index.cshtml"
echo '<nav>users</nav>' > "$N/Api/Shared/Nav.razor"
echo 'public record Dto(Guid Id);' > "$N/Api/Dto.cs"
printf '#[post("/api/reports")]\nasync fn report() -> impl Responder { "" }\n' > "$N/tools/src/main.rs"

cat > "$G/src/app/users/user.service.ts" <<'EOF'
export interface ChangeEmailResponse { refreshToken: string; }
@Injectable({ providedIn: 'root' })
export class UserService {
  constructor(private http: HttpClient) {}
  changeEmail(id: string, email: string) {
    return this.http.post<ChangeEmailResponse>(`${this.base}/api/users/${id}/email`, { email });
  }
  remove(id: string) { return this.http.delete(`${this.base}/api/users/${id}`); }
  report(body: unknown) { return this.http.post('/api/reports', body); }
  list() { return this.http.get(`${this.base}/api/users`); }
  label = 'avatar';
  legacy = '/avatar-legacy';
  many = '/api/users/avatars';
  // POST /api/users/{id}/avatar
}
EOF
cat > "$G/src/app/users/session.service.ts" <<'EOF'
export class SessionService {
  refresh() { return this.http.post<{ accessToken: string; expiresIn: number }>(`${environment.apiUrl}/api/sessions/refresh`, {}); }
}
EOF
echo 'export class UserComponent {}' > "$G/src/app/users/user.component.ts"
echo '<p>user</p>' > "$G/src/app/users/user.component.html"
echo 'p { margin: 0; }' > "$G/src/app/users/user.component.scss"

cat > "$J/src/main/java/com/acme/OrderController.java" <<'EOF'
@RestController
@RequestMapping("/api/orders")
public class OrderController {
  @PostMapping("/{orderId}/cancel")
  public CancelResponse cancel(@PathVariable String orderId) { return new CancelResponse(refundId); }
  @GetMapping("/api/invoices")
  public List<Invoice> invoices() { return List.of(); }
}
EOF
cat > "$K/app/src/main/kotlin/com/acme/OrdersClient.kt" <<'EOF'
data class CancelResult(val refundId: String)
class OrdersClient(private val client: HttpClient, private val baseUrl: String) {
  suspend fun cancel(id: String): CancelResult = client.post("$baseUrl/api/orders/$id/cancel").body()
  suspend fun invoices() = client.get("$baseUrl/api/invoices").body<List<Invoice>>()
}
EOF
for r in "$N" "$G" "$J" "$K"; do commit_at "$r" 2026-01-01 base; done
NSHA="$(git -C "$N" rev-parse --short HEAD)"

S="$N/.claude/specs"
REFINE='## Refine
Round 1/1, 2026-01-02. Critic: agon nero (normal risk).'
spec dotnet-angular <<EOF
# C# producer, Angular consumer
**Status:** DONE
## Contract
| Endpoint | Fields | Producer | Consumers |
|---|---|---|---|
| \`POST /api/users/{id}/email\` | \`accessToken\`, \`refreshToken\` | dotnet | ng |
| \`POST /api/sessions/refresh\` | \`accessToken\`, \`expiresIn\` | dotnet | ng |
| \`POST /api/reports\` | | dotnet | ng |
| \`DELETE /api/users/{id}\` | | dotnet | ng |
$REFINE
EOF
spec spring-kotlin <<EOF
# Spring producer, Kotlin consumer
**Status:** DONE
## Contract
| Endpoint | Fields | Producer | Consumers |
|---|---|---|---|
| \`POST /api/orders/{orderId}/cancel\` | \`refundId\` | spring | kt |
| \`GET /api/invoices\` | | spring | kt |
$REFINE
EOF
spec generic-strings <<EOF
# Generic strings are not evidence
**Status:** DONE
## Contract
| Endpoint | Fields | Producer | Consumers |
|---|---|---|---|
| \`POST /api/users/{id}/avatar\` | | dotnet | ng |
$REFINE
EOF
spec stack-paths <<EOF
# Stack paths
**Status:** DONE
**Verified at:** $NSHA
## Changes
MODIFIED: \`Api/Controllers/UsersController.cs\`, \`Api/Api.csproj\` — endpoint
MODIFIED: \`Api/Pages/Index.cshtml\`, \`Api/Shared/Nav.razor\` — views
MODIFIED: \`ng:src/app/users/user.component.ts\`, \`ng:src/app/users/user.component.html\`, \`ng:src/app/users/user.component.scss\`
MODIFIED: \`spring:src/main/java/com/acme/OrderController.java\` — cancel
MODIFIED: \`kt:app/src/main/kotlin/com/acme/OrdersClient.kt\` — client
$REFINE
EOF
spec added-cs <<EOF
# Added C# file
**Status:** DONE
## Changes
ADDED: \`Api/Services/NewService.cs\` — service
$REFINE
EOF
spec identifiers <<EOF
# Identifiers are not paths
**Status:** DONE
**Date:** 2026-01-02
## Changes
ADDED: \`Api/Dto.cs\` — exposes \`user.id\`, \`Foo.Bar\`, \`access_token\`, \`foo.bar()\`, \`System.Text.Json\`, \`application/json\`, \`HttpContext.User\`
MODIFIED: \`UserService.changeEmail\` via \`this.http.post<T>\` and \`req.body.email\`
- \`Foo.Bar:12\` VERIFIED, \`user.id:3\` VERIFIED
$REFINE
EOF
spec review-present <<EOF
# Review present
**Status:** READY TO BUILD
$REFINE
EOF
spec review-missing <<'EOF'
# Review missing
**Status:** IN PROGRESS
EOF
spec review-empty <<'EOF'
# Review empty
**Status:** DONE
## Refine
Round 1/1, 2026-01-02. **Critic:** <name>
Pass: yes
EOF
spec review-draft <<'EOF'
# Review draft
**Status:** SPEC
EOF
commit_at "$N" 2026-01-03 specs
for f in Api/Controllers/UsersController.cs Api/Api.csproj Api/Pages/Index.cshtml Api/Shared/Nav.razor; do echo '// x' >> "$N/$f"; done
commit_at "$N" 2026-02-01 change
for f in src/app/users/user.component.ts src/app/users/user.component.html src/app/users/user.component.scss; do echo ' ' >> "$G/$f"; done
commit_at "$G" 2026-02-01 change
echo ' ' >> "$J/src/main/java/com/acme/OrderController.java"; commit_at "$J" 2026-02-01 change
echo ' ' >> "$K/app/src/main/kotlin/com/acme/OrdersClient.kt"; commit_at "$K" 2026-02-01 change

OUT="$("$CHECK" --repos ng=../ng,spring=../spring,kt=../kt "$N" 2>&1)"
has CONTRACT-FIELDS ".claude/specs/dotnet-angular/spec.md: ng ignores \`accessToken\` of POST /api/users/{id}/email (src/app/users/user.service.ts:6"
hasnt CONTRACT-FIELDS ".claude/specs/dotnet-angular/spec.md: ng ignores \`accessToken\`, "
hasnt CONTRACT-FIELDS ".claude/specs/dotnet-angular/spec.md: .* of POST /api/sessions"
hasnt CONTRACT-MISSING ".claude/specs/dotnet-angular/"
hasnt "CONTRACT-[A-Z]*" ".claude/specs/spring-kotlin/"
has CONTRACT-MISSING ".claude/specs/generic-strings/spec.md: POST /api/users/{id}/avatar — dotnet: missing everywhere (last 20 refs); ng: missing everywhere"
has STALE ".claude/specs/stack-paths/spec.md: 4 files:"
has XREPO ".claude/specs/stack-paths/spec.md: 5 files:"
has UNMERGED ".claude/specs/added-cs/spec.md: 1 ADDED paths not on the default branch while Status is 'DONE': dotnet:Api/Services/NewService.cs nowhere"
hasnt "[A-Z-]*" ".claude/specs/identifiers/"
hasnt NO-REVIEW ".claude/specs/review-present/"
has NO-REVIEW ".claude/specs/review-missing/spec.md: Status 'IN PROGRESS' but no ## Refine section"
has NO-REVIEW ".claude/specs/review-empty/spec.md: Status 'DONE' but ## Refine names no Critic"
hasnt NO-REVIEW ".claude/specs/review-draft/"
hasnt NO-REVIEW ".claude/specs/dotnet-angular/"
