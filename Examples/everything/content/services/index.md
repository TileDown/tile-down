---
title: Services
weight: 25
description: A generated service form backed by a local contract.
---
# Services

The form below is generated from `contracts/calculator.json`. The contract stays
out of the published site, while the browser receives a static form, validation
logic, and a proxy endpoint path.

:::tile service-form
id: price-calculator
service: calculator
operation: positive-decimal-calculation
mode: proxy
submitLabel: Calculate
:::

The Buttondown form below demonstrates a static external-source tile. It posts
directly to Buttondown while Tiledown generates the confirmation landing pages
that Buttondown can redirect readers to.

:::tile buttondown
username: tiledown
title: Tiledown Dispatch
body: Notes about the Tiledown engine, tile authoring, and developer workflows.
emailLabel: Developer email
placeholder: developer@example.com
buttonLabel: Subscribe
note: This fixture uses Buttondown's embed endpoint without adding runtime code.
tags:
- tiledown
- developers
metadata.source: everything-fixture
thanksBody: Check your inbox to confirm the Tiledown Dispatch subscription.
confirmedBody: You are subscribed to Tiledown Dispatch.
:::
