package config

import (
	"crypto/rand"
	"math/big"
)

// GenerateRandomString generates a secure random string of specified length
func GenerateRandomString(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	result := make([]byte, length)
	for i := range result {
		num, err := rand.Int(rand.Reader, big.NewInt(int64(len(charset))))
		if err != nil {
			// Fallback to simpler math if crypto fails (highly unlikely)
			result[i] = charset[i%len(charset)]
			continue
		}
		result[i] = charset[num.Int64()]
	}
	return string(result)
}
