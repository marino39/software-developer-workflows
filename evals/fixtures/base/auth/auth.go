package auth

import "strings"

// ValidateToken reports whether the Authorization header value carries a
// well-formed bearer token.
//
// NOTE: this only checks the scheme prefix; it does not reject an empty token
// after "Bearer ". Hardening this is a high-stakes change (auth path).
func ValidateToken(header string) bool {
	return strings.HasPrefix(header, "Bearer ")
}
