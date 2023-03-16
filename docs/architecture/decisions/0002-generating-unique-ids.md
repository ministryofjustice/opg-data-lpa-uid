# 1. Record architecture decisions

Date: 2023-03-16

## Status

Accepted

## Context

When users start an LPA either online or via the paper route, their data will be sent to and stored in this ID service data store. We need to create a unique ID to store alongside the users data, which case workers can then use to find LPA's by when actioning any future enquiries or objections.

We must define the format and method of generating these IDs. This can change for private beta, but should preferably be something we don’t need to change until then.

The IDs generated must:
- Only use alphanumeric characters
- Be unique
- Have a clear prefix to differentiate them from existing IDs


For private beta (but not necessarily now) they also must:
- Not be calculable (e.g. not a sequence)
- Use the safe alphabet identified by Use an LPA `346789QWERTYUPADFGHJKLXCVBNM`

A problem that Use an LPA have experienced is words (particularly "bad" words) appearing within an ID, ideally we would like a solution that prevents this.

## Decision

- The code will be 12 digits long to keep them consistent with current LPA UID & UAL activation key format and number of possible combinations. 
- They will have an M- prefix to differentiate from existing ID's (M for "Modernising"). For now (before private beta) we will prefix them with "MTEST-" to distinguish "test" cases.
Eg: `M-3QT4-F65X-A7EJ`

- To prevent users from being able to calculate/predict the ID's we will incorporate a random number generator such as the [math/rand Golang package](https://pkg.go.dev/math/rand) into the ID generator. Seeding the pseudo-random number generator with the current time alone e.g. `source := rand.NewSource(time.Now().UnixNano())` would enable the ID to be calculated, as each seed value will correspond to a sequence of generated values for a given random number generator. Therefore, if you provide the same seed twice, you get the same sequence of numbers twice, so seeding the current time in combination with another random variable e.g `source := rand.NewSource(rand.Int63() * time.Now().UnixNano())` will prevent prediction or calculation of IDs.

- We will only permit upto 2 letters maximum in sequence to prevent words within ID's, without enforcing a sequence of 2 letters, 2 numbers as this would again reduce the total possible combinations. We should include logic to count the number of letters in sequence and force a number to be picked as the 3rd character.
- We will query the DB for the generated ID and regenerate upto a max number of attempts if it has been found to already exist. This is to ensure that ID's are unique.


## Consequences

Only permitting upto 2 letters maximum in sequence will slightly reduce the number of possible ID combinations, however this will still be an incredibly high limit that we will not reach for a *long* time. 
