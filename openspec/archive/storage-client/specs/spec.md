# Spec: storage-client

## Requirements

### Requirement: Write value

The system SHALL persist a string value associated with a key in secure storage.

#### Scenario: write stores value

Given a key and a value
When `IStorageClient.write` is called
Then the value is persisted and retrievable via `read`

---

### Requirement: Read value

The system SHALL return the stored value for a given key, or `null` if not found.

#### Scenario: read returns stored value

Given a key with a previously written value
When `IStorageClient.read` is called
Then it returns the stored string

#### Scenario: read returns null for unknown key

Given a key that was never written
When `IStorageClient.read` is called
Then it returns `null`

---

### Requirement: Delete value

The system SHALL remove a single entry from secure storage.

#### Scenario: delete removes entry

Given a key with a stored value
When `IStorageClient.delete` is called
Then `read` for that key returns `null`

---

### Requirement: Clear all values

The system SHALL remove all entries from secure storage.

#### Scenario: clear removes all entries

Given multiple stored keys
When `IStorageClient.clear` is called
Then `read` for any key returns `null`
