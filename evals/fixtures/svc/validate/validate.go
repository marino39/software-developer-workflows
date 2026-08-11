package validate

// MaxIDLen is the longest accepted item ID.
const MaxIDLen = 32

// ID reports whether id is acceptable: non-empty and at most MaxIDLen bytes.
func ID(id string) bool {
	return id != "" && len(id) <= MaxIDLen
}
