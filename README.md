# INFO-GO API documentation and scraper

[INFO-GO](http://www.infogo.gov.on.ca/infogo/) is the Government of Ontario Employee and Organization Directory.

## Scraper

Writes one JSON file per organization and person to `organizations` (7,000+) and `people` (40,000+) directories:

```
bundle
ruby scraper.rb
```

INFO-GO changes daily, so I'm not currently distributing the scraper's output.

Requires Ruby 2.3 for `Hash#dig`.

## API base URL

The base URL is `http://www.infogo.gov.on.ca/infogo/v1`

Quirks:

* The response has `Content-Type: text/plain;charset=ISO-8859-1`. You may have expected `Content-Type: application/json;charset=UTF-8`.
* The identifiers for people (`assignmentId`) are unstable.

## API endpoints

For brevity, I refer to [common schemas](#common-schemas) in the sample output of API endpoints.

### GET `/organizations/categories`

Returns the root organizations.

```json
{
  "categories": [{
    "categoryCode": "",
    "categoryDisplayOrder": 0,
    "categoryId": 0,
    "categoryName": "",
    "categoryNameFrench": "",
    "organizations": [{
      "description": "",
      "descriptionFrench": "",
      "id": 0,
      "name": "",
      "nameFrench": "",
      "nameFrenchNorm": "",
      "nameNorm": "",
      "typeId": 0,
      "typeName": ""
    }]
  }]
}
```

Relations:

* Use `categories[].organizations[].id` in `/organizations/get?orgId=<id>`

### GET `/organizations/get?orgId=<id>`

Returns one organization.

```json
{
  "_id": 0,
  "orgName": "",
  "orgNameFr": "",
  "orgPrefix": "",
  "orgPrefixFr": "",
  "orgAcronym": "",
  "orgType": "",
  "orgTypeFr": "",
  "category": "",
  "categoryFr": "",
  "description": "",
  "descriptionFr": "",
  "topLevel": true,
  "path": [organization],
  "addresses": [address],
  "phones": [{
    "phoneType": {
      "code": "",
      "label": "",
      "labelFr": "",
      "order": 0,
      "orderFr": 0
    },
    "phoneNumber": "",
    "phoneNumberFr": "",
    "description": "",
    "descriptionFr": ""
  }],
  "emails": [email],
  "urls": [{
    "url": "",
    "primary": true
  }],
  "childOrgs": [organization_with_head],
  "positions": [position],
  "indirectOrgs": [{
    "categoryId": 0,
    "category": "",
    "categoryFr": "",
    "orgs": [{
      "relationshipType": type,
      "orgId": 0,
      "orgName": "",
      "orgNameFr": "",
      "orgPrefix": "",
      "orgPrefixFr": "",
      "orgAcronym": "",
      "topOrg": {
        "orgId": 0,
        "orgName": "",
        "orgNameFr": "",
        "orgPrefix": "",
        "orgPrefixFr": "",
        "orgAcronym": ""
      },
      "orgType": "",
      "orgTypeFr": ""
    }]
  }],
  "indirectPositions": []
}
```

Direct relations:

* Use `childOrgs[].orgId` in `/organizations/get?orgId=<id>`
* Use `childOrgs[].head.assignmentId` in `/individuals/get?assignmentId=<id>`
* Use `positions[].assignmentId` in `/individuals/get?assignmentId=<id>`

Quirks:

* The record for the identifier `childOrgs[].head.assignmentId` sometimes doesn't exist.

### GET `/individuals/get?assignmentId=<id>`

Returns one individual.

```json
{
  "_id": 0,
  "assignmentType": type,
  "positionId": 0,
  "positionTitle": "",
  "positionTitleFr": "",
  "associatedOrg": organization_with_path,
  "individualId": 0,
  "individualName": "",
  "individualNameFr": "",
  "firstName": "",
  "lastName": "",
  "middleName": "",
  "honorific": "",
  "honorificFr": "",
  "head": true,
  "role": true,
  "active": true,
  "emails": [email],
  "phones": [{
    "phoneType": {
      "code": "",
      "label": "",
      "labelFr": ""
    },
    "phoneNumber": "",
    "phoneNumberFr": "",
    "description": "",
    "descriptionFr": "",
    "primary": true
  }],
  "addresses": [address],
  "reportsTo": position_with_associatedOrg,
  "otherPositionAssignments": [position_with_associatedOrg]
}
```

Quirks:

* `individualId` can be nil.

### GET `/organizations/search?&keywords=<keywords>&topOrgId=<id>&locale=<locale>`

Returns matching organizations.

* `topOrgId` is any organization with `"topLevel": true`
* `locale` is either `en` or `fr`

```json
{
  "organizations": [{
    "addresses": [],
    "description": null,
    "descriptionFragment": "",
    "displayAddress": {
        "addressId": 0,
        "buildingName": "",
        "city": "",
        "mailing": true,
        "matched": 0,
        "postalCode": "",
        "primary": true,
        "street": ""
    },
    "displayPhone": "",
    "id": 0,
    "name": "",
    "nameNorm": "",
    "phones": "",
    "score": 0.0,
    "topOrgId": 0,
    "topOrgName": ""
  }],
  "total": 0
}
```

Strings are null if empty.

### GET `/individuals/search?&keywords=<keywords>&topOrgId=<id>&locale=<locale>`

Returns matching individuals.

* `topOrgId` is any organization with `"topLevel": true`
* `locale` is either `en` or `fr`

```json
{
  "individuals": [{
    "assignments": [{
      "assignmentCode": "",
      "assignmentId": 0,
      "assignmentName": null,
      "assignmentType": "",
      "displayEmail": "",
      "displayPhone": "",
      "emails": "",
      "orgId": 0,
      "orgName": "",
      "orgNameNorm": "",
      "phones": "",
      "positionId": 0,
      "positionTitle": "",
      "topOrgId": 0,
      "topOrgName": ""
    }],
    "firstName": "",
    "honorifics": "",
    "individualId": 0,
    "lastName": "",
    "middleName": ""
  }],
  "total": 0
}
```

Strings are null if empty.

Quirks:

* The key is `honorifics` here but `honorific` in `/individuals/get?assignmentId=<id>`

### GET `/organizations/top`

Returns a subset of the root organizations, to display in a dropdown.

```json
{
  "organizations": [{
    "description": "",
    "descriptionFrench": "",
    "id": 0,
    "name": "",
    "nameFrench": "",
    "nameFrenchNorm": "",
    "nameNorm": "",
    "typeId": 0,
    "typeName": ""
  }]
}
```

Quirks:

* `id` can be a string.
* The entries for `All Organizations`, `Agencies` and `Universities and Community Colleges` have only the keys `id`, `name` and `nameFrench`.

## Common schemas

### Address

```json
{
  "primary": true,
  "mailing": true,
  "address": "",
  "addressFr": "",
  "street": "",
  "postalCode": "",
  "city": "",
  "province": ""
}
```

### Email

```json
{
  "emailAddress": "",
  "primary": true
}
```

### Organization

```json
{
  "orgId": 0,
  "orgName": "",
  "orgNameFr": "",
  "orgPrefix": "",
  "orgPrefixFr": "",
  "orgAcronym": ""
}
```

* `organization_with_head`: as above, plus a `"head"` key with a `position` value.
* `organization_with_path`: as above, plus a `"path"` key with a `[organization]` value.

### Position

```json
{
  "assignmentId": 0,
  "assignmentType": type,
  "positionTitle": "",
  "positionTitleFr": "",
  "individualName": "",
  "individualNameFr": "",
  "head": true,
  "role": true,
  "active": true,
  "primaryEmail": "",
  "primaryPhone": "",
  "primaryPhoneFr": ""
}
```

* `position_with_associatedOrg`: as above, plus an `"associatedOrg"` key with an `organization` value.

### Type

```json
{
  "code": "",
  "label": "",
  "labelFr": ""
}
```

Copyright (c) 2016 James McKinney, released under the MIT license
