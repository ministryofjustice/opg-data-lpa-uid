package main

import (
	"crypto/rand"
	"math/big"
	"strconv"
)

func generateUID() (string, error) {
	allChars := []string{"3", "4", "6", "7", "8", "9", "Q", "W", "E", "R", "T", "Y", "U", "P", "A", "D", "F", "G", "H", "J", "K", "L", "X", "C", "V", "B", "N", "M"}
	numChars := []string{"3", "4", "6", "7", "8", "9"}

	var v int64
	uid := "MTEST-"
	lettersInSequence := 0

	for i := 1; i <= 12; i++ {
		if lettersInSequence == 2 {
			index, err := rand.Int(rand.Reader, big.NewInt(int64(len(numChars))))
			if err != nil {
				return "", err
			}
			v = index.Int64()
			lettersInSequence = 0
		} else {
			index, err := rand.Int(rand.Reader, big.NewInt(int64(len(allChars))))
			if err != nil {
				return "", err
			}
			v = index.Int64()

			if _, err := strconv.Atoi(allChars[v]); err != nil {
				lettersInSequence++
			} else {
				lettersInSequence = 0
			}
		}

		uid = uid + allChars[v]
	}

	return uid, nil
}
