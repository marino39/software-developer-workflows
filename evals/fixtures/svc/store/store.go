package store

// Item is a stored record.
type Item struct {
	ID   string
	Name string
}

// Store is an in-memory item store.
type Store struct {
	items map[string]Item
}

// New returns an empty Store.
func New() *Store {
	return &Store{items: make(map[string]Item)}
}

// Put stores it, overwriting any item with the same ID.
func (s *Store) Put(it Item) {
	s.items[it.ID] = it
}

// Get returns the item for id. The bool reports whether it was found.
func (s *Store) Get(id string) (Item, bool) {
	it, ok := s.items[id]
	return it, ok
}
