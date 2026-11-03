# beta errors are informative

    Code
      beta_pair(toy()[toy()$site == "a", ])
    Condition
      Error in `beta_pair()`:
      ! Beta diversity needs at least two sites in each group.
    Code
      beta_pair(toy(), index = "bray")
    Condition
      Error in `beta_pair()`:
      ! `index` must be one of "sorensen" or "jaccard", not "bray".
    Code
      beta_decay(toy(), gradient = abundance)
    Condition
      Error in `beta_decay()`:
      ! `gradient` must be constant within each site.

