package cart

import "errors"

// Item is a single line in a cart.
type Item struct {
	Name  string
	Price int // unit price, in cents
	Qty   int
}

var (
	errEmptyCart = errors.New("cart: empty")
	errBadQty    = errors.New("cart: non-positive quantity")
)

// Checkout is the entry point: it computes the payable total (in cents) for the
// items after applying the discount named by code. It validates the cart, sums
// the line items, then applies the matching discount strategy.
func Checkout(items []Item, code string) (int, error) {
	if err := validate(items); err != nil {
		return 0, err
	}
	sub := subtotal(items)
	return applyDiscount(sub, code), nil
}

// validate rejects an empty cart or any non-positive quantity.
func validate(items []Item) error {
	if len(items) == 0 {
		return errEmptyCart
	}
	for _, it := range items {
		if it.Qty <= 0 {
			return errBadQty
		}
	}
	return nil
}

// subtotal sums price*qty across all items.
func subtotal(items []Item) int {
	total := 0
	for _, it := range items {
		total += it.Price * it.Qty
	}
	return total
}

// applyDiscount dispatches to the discount strategy named by code, falling back
// to the un-discounted subtotal for an unknown code.
func applyDiscount(sub int, code string) int {
	switch code {
	case "SAVE10":
		return discountPercent(sub, 10)
	case "MINUS5":
		return discountFlat(sub, 500)
	default:
		return sub
	}
}
