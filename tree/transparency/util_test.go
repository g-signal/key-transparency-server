package transparency

import (
	"crypto/rand"
	"testing"

	"github.com/signalapp/keytransparency/cmd/shared"
)

var (
	validAci          = random(16)
	validUsernameHash = random(32)
	validPhoneNumber  = "+14155550101"
)

func TestGetSearchKeyType(t *testing.T) {
	tests := []struct {
		name           string
		searchKeyBytes []byte
		expectedType   string
		expectError    bool
	}{
		{
			name:           "ACI prefix returns AciLabel",
			searchKeyBytes: append([]byte{shared.AciPrefix}, validAci...),
			expectedType:   AciLabel,
			expectError:    false,
		},
		{
			name:           "UsernameHash prefix returns UsernameHashLabel",
			searchKeyBytes: append([]byte{shared.UsernameHashPrefix}, validUsernameHash...),
			expectedType:   UsernameHashLabel,
			expectError:    false,
		},
		{
			name:           "Number prefix returns NumberLabel",
			searchKeyBytes: append([]byte{shared.NumberPrefix}, []byte(validPhoneNumber)...),
			expectedType:   NumberLabel,
			expectError:    false,
		},
		{
			name:           "empty byte slice returns error",
			searchKeyBytes: []byte{},
			expectedType:   "",
			expectError:    true,
		},
		{
			name:           "unrecognized prefix returns error",
			searchKeyBytes: append([]byte{'s'}, validAci...),
			expectedType:   "",
			expectError:    true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := getSearchKeyType(tt.searchKeyBytes)

			if tt.expectError {
				if err == nil {
					t.Errorf("expected error but got none")
				}
			} else {
				if err != nil {
					t.Errorf("unexpected error: %v", err)
				}
				if result != tt.expectedType {
					t.Errorf("expected type %q, got %q", tt.expectedType, result)
				}
			}
		})
	}
}

func random(length int) []byte {
	out := make([]byte, length)
	if _, err := rand.Read(out); err != nil {
		panic(err)
	}
	return out
}
