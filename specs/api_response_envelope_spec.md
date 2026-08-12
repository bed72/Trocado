# Spec: API Response Envelope

## Context

The Kotlin backend uses a common HTTP response envelope inspired by JSON:API,
without implementing JSON:API strictly. Every remote datasource SHALL consume
this envelope before deserializing feature-specific payloads.

## Success Envelope

### Requirement: Single resource response

Successful responses containing one resource SHALL expose that resource inside a
`data` property.

#### Scenario: Single resource

Given a successful response body

```json
{
  "data": {
    "id": "123",
    "name": "Exemplo"
  }
}
```

When the HTTP response is processed

Then the datasource SHALL deserialize `data` as the feature response
And feature response parsers SHALL not read resource fields from the envelope root

### Requirement: Collection response

Successful responses containing a collection SHALL expose the collection inside
the `data` property as an array.

#### Scenario: Collection

Given a successful response body with `data` as an array

```json
{
  "data": [
    { "id": "1" },
    { "id": "2" }
  ]
}
```

When the HTTP response is processed

Then the datasource SHALL deserialize each item from `data`
And the resulting feature response SHALL contain both items

### Requirement: Collection pagination metadata

Paginated collection responses SHALL preserve the optional `meta.pagination`
and `links` objects for consumers that need cursor navigation.

#### Scenario: Collection with cursor pagination

Given a successful response body

```json
{
  "data": [],
  "meta": {
    "pagination": {
      "next_cursor": "abc"
    }
  },
  "links": {
    "self": "/v1/expenses",
    "next": "/v1/expenses?cursor=abc"
  }
}
```

When the HTTP response is processed

Then `data` SHALL be exposed as an empty collection
And `meta.pagination.next_cursor` SHALL be preserved
And `links.self` SHALL be preserved
And `links.next` SHALL be preserved

## Error Envelope

### Requirement: Standard error response

Error responses SHALL use the plural `errors` property, whose value is always an
array. Each error item SHALL support `status`, `code`, and `message`.

#### Scenario: General error

Given an error response body

```json
{
  "errors": [
    {
      "status": "422",
      "code": "INVALID_AMOUNT",
      "message": "O valor informado é inválido."
    }
  ]
}
```

When the error response is processed

Then `errors` SHALL be deserialized as one error item
And `status` SHALL equal `"422"`
And `code` SHALL equal `"INVALID_AMOUNT"`
And `message` SHALL equal `"O valor informado é inválido."`

### Requirement: Field validation error

Error items MAY contain `source.field` to identify the invalid request field.

#### Scenario: Validation error by field

Given an error response body containing `source.field = "email"`

```json
{
  "errors": [
    {
      "status": "400",
      "code": "INVALID_REQUEST",
      "message": "O e-mail é inválido.",
      "source": {
        "field": "email"
      }
    }
  ]
}
```

When the error response is processed

Then the error item SHALL preserve `source.field`
And failure mapping SHALL be able to use `email` as the affected field

### Requirement: Multiple errors

The client SHALL preserve every item in the `errors` array and SHALL not discard
additional errors after the first one.

#### Scenario: Multiple API errors

Given an error response containing multiple entries in `errors`
When the response is processed
Then the resulting failure response SHALL contain the same number of entries

## HTTP Client Boundary

### Requirement: Envelope-safe transport

The HTTP client SHALL return the decoded HTTP body without interpreting
feature-specific fields. Envelope extraction SHALL happen in the response or
datasource mapping layer, where the expected payload type is known.

#### Scenario: Successful transport

Given any successful HTTP response
When the HTTP client returns the body
Then it SHALL preserve `data`, `meta`, and `links`

#### Scenario: Error transport

Given any HTTP error with an `errors` array
When the HTTP client returns the body
Then it SHALL preserve every error field, including nested `source.field`

## Migration Rules

- All remote datasources SHALL deserialize success payloads from `data`.
- Collection responses SHALL use a shared representation for `data`, `meta`, and
  `links` instead of feature-specific envelope parsing.
- `FailureResponse` SHALL model `status` and nested `source.field`.
- The legacy error field at the root of an error item SHALL not be used for the
  Kotlin API contract.
- The envelope SHALL not be treated as strict JSON:API.

## Out of Scope

- HTTP status-code policy beyond preserving the response status when supplied
- Pagination UI or pagination behavior in individual features
- JSON:API compliance or JSON:API-specific document links
- Changes to domain failure messages

## Approval Gate

Implementation SHALL NOT begin until this spec is approved.
