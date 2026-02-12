package transparency

import (
	"fmt"

	"github.com/hashicorp/go-metrics"

	"github.com/signalapp/keytransparency/cmd/shared"
)

const (
	AciLabel          = "aci"
	NumberLabel       = "e164"
	UsernameHashLabel = "username_hash"
)

func getSearchKeyType(searchKeyBytes []byte) (string, error) {
	if len(searchKeyBytes) == 0 {
		return "", fmt.Errorf("empty search key")
	}

	switch searchKeyBytes[0] {
	case shared.AciPrefix:
		return AciLabel, nil
	case shared.NumberPrefix:
		return NumberLabel, nil
	case shared.UsernameHashPrefix:
		return UsernameHashLabel, nil
	default:
		return "", fmt.Errorf("unknown search key type: %v", searchKeyBytes[0])
	}
}

func GetSearchKeyTypeLabel(searchKeyBytes []byte) (metrics.Label, error) {
	searchKeyType, err := getSearchKeyType(searchKeyBytes)
	return metrics.Label{Name: "search_key_type", Value: searchKeyType}, err
}
