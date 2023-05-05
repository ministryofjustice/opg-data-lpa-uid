package main

import (
	"crypto/rand"
	"math"
	"math/big"
	"strconv"
	"strings"
)

const UID_PREFIX = "M-"

var AllChars = []string{"3", "4", "6", "7", "8", "9", "Q", "W", "E", "R", "T", "Y", "U", "P", "A", "D", "F", "G", "H", "J", "K", "L", "X", "C", "V", "B", "N", "M"}
var N = float64(len(AllChars))

func generateUID() (string, error) {
	numChars := []string{"3", "4", "6", "7", "8", "9"}

	uid := ""
	lettersInSequence := 0

	for x := 1; x <= 11; x++ {
		max := len(AllChars)

		if lettersInSequence == 2 {
			max = len(numChars)
		}

		index, err := rand.Int(rand.Reader, big.NewInt(int64(max)))
		if err != nil {
			return "", err
		}

		i := index.Int64()
		if _, err := strconv.Atoi(AllChars[i]); err != nil {
			lettersInSequence++
		} else {
			lettersInSequence = 0
		}

		uid = uid + AllChars[i]
	}

	checksum := generateChecksum(uid)

	return UID_PREFIX + uid + checksum, nil
}

func generateChecksum(uid string) string {
	sum := checksumCalculation(uid, 2)

	remainder := math.Mod(sum, N)
	checkCodePoint := math.Mod(N-remainder, N)

	return AllChars[int(checkCodePoint)]
}

func validateChecksum(uid string) bool {
	sum := checksumCalculation(uid, 1)
	remainder := math.Mod(sum, N)
	return remainder == 0
}

func checksumCalculation(uid string, factor int) float64 {
	var sum = 0.00

	for i := len(uid) - 1; i >= 0; i-- {
		codePoint := strings.Index("346789QWERTYUPADFGHJKLXCVBNM", strings.Split(uid, "")[i])
		var addend = float64(factor * codePoint)

		if factor == 2 {
			factor = 1
		} else {
			factor = 2
		}

		addend = math.Floor(addend/N) + math.Mod(addend, N)
		sum = sum + addend
	}

	return sum
}
