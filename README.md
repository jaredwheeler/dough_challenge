## Code Challenge : Dough



This implementation started from a boilerplate Master/Detail setup for its device universality and handy FetchedResultsController-ness.  It includes a CoreData stack for persistence. The NASDAQ listing data is included in the app bundle, and on first launch it gets populated into the CoreData store.

The detail view requests the quote data every time the it's loaded.  Given that the CoreData stack exists here, implementing some caching/eviction rules would be simple enough. Leaving that bit out of scope for this exercise.

The symbol list can be filtered using the standard iOS search field in the TableView header.  It resets the FRC predicate as characters are entered, filtering the list down as you type.

Played around with a 3rd-party Swift charting lib (https://github.com/i-schuetz/SwiftCharts), but found it to be a tad overwrought/underdocumented for a code challenge.  Opted instead for a minimalist CGContext approach.  It's not really presented as a complete implementation, but is meant to illustrate comfort working within the Quartz environment.  Were I to continue, I'd add legends, interactivity, animations, etc.

I'll also note that there isn't a coherent error handling model present.  I'm leaving that out of scope, but wanted to flag that as another thing I would spend some time on in a real-world implementation