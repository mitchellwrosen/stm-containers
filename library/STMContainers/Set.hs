module STMContainers.Set
(
  Set,
  Indexable,
  new,
  insert,
  delete,
  lookup,
  foldM,
  null,
)
where

import STMContainers.Prelude hiding (insert, delete, lookup, alter, foldM, toList, empty, null)
import qualified STMContainers.HAMT as HAMT
import qualified STMContainers.HAMT.Nodes as HAMTNodes
import qualified Focus


-- |
-- A hash set, based on an STM-specialized hash array mapped trie.
type Set e = HAMT.HAMT (Element e)

-- |
-- A standard constraint for elements.
type Indexable a = (Eq a, Hashable a)

newtype Element e = Element e

instance (Eq e) => HAMTNodes.Element (Element e) where
  type ElementKey (Element e) = e
  elementKey (Element e) = e

{-# INLINABLE elementValue #-}
elementValue :: Element e -> e
elementValue (Element e) = e

{-# INLINABLE insert #-}
insert :: (Indexable e) => e -> Set e -> STM ()
insert e = HAMT.insert (Element e)

{-# INLINABLE delete #-}
delete :: (Indexable e) => e -> Set e -> STM ()
delete = HAMT.focus Focus.deleteM

{-# INLINABLE lookup #-}
lookup :: (Indexable e) => e -> Set e -> STM Bool
lookup e = fmap (maybe False (const True)) . HAMT.focus Focus.lookupM e

{-# INLINABLE foldM #-}
foldM :: (a -> e -> STM a) -> a -> Set e -> STM a
foldM f = HAMT.foldM (\a -> f a . elementValue)

{-# INLINABLE new #-}
new :: STM (Set e)
new = HAMT.new

{-# INLINABLE null #-}
null :: Set e -> STM Bool
null = HAMT.null
