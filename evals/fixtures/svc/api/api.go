package api

import (
	"evalsvc/store"
	"evalsvc/validate"
)

// Lookup returns the name of the item with the given id, or "" when the id is
// invalid or no such item exists. Callers cannot tell those two cases apart.
func Lookup(s *store.Store, id string) string {
	if !validate.ID(id) {
		return ""
	}
	it, ok := s.Get(id)
	if !ok {
		return ""
	}
	return it.Name
}
