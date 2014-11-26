The doc extractor was written with the sole purpose to allow for automated extraction of Google APIs that are provided as JS typed objects as a third party units to build upon and in the same time do NOT include the externs for that set of objects/types for the closure compiler.

The code makes attempts to extract the namespaced objecta and the type information to form an extern file.

The following assumptions are made:

- the first argument is the URL to load initially and contains all links to the relevant docs
- the domain is developer.google.com

Once the list of links is collected, all links should be loaded in memory and processed, once per document until the list is exhausted. The resulting data structure will then be available as string.

Usage:

    node docextractor.js /cast/docs/reference/chrome/

where link is the the url of the initial document.

Note that no external resources will be loaded or processed.