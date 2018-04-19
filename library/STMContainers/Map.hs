module STMContainers.Map
(
  Map,
  new,
  newIO,
  insert,
  delete,
  deleteAll,
  lookup,
  focus,
  null,
  size,
  stream,
)
where

import STMContainers.Prelude hiding (insert, delete, lookup, alter, foldM, toList, empty, null)
import qualified STMContainers.HAMT as HAMT
import qualified STMContainers.HAMT.Nodes as HAMTNodes
import qualified Focus


-- |
-- A hash table, based on an STM-specialized hash array mapped trie.
newtype Map k v = Map (HAMT.HAMT (k, v))
  deriving (Typeable)

instance (Eq k) => HAMTNodes.Element (k, v) where
  type ElementKey (k, v) = k
  elementKey (k, v) = k

{-# INLINE associationValue #-}
associationValue :: (k, v) -> v
associationValue (_, v) = v

-- |
-- Look up an item.
{-# INLINE lookup #-}
lookup :: (Eq k, Hashable k) => k -> Map k v -> STM (Maybe v)
lookup k = focus Focus.lookupM k

-- |
-- Insert a value at a key.
{-# INLINE insert #-}
insert :: (Eq k, Hashable k) => v -> k -> Map k v -> STM ()
insert !v !k (Map h) = HAMT.insert (k, v) h

-- |
-- Delete an item by a key.
{-# INLINE delete #-}
delete :: (Eq k, Hashable k) => k -> Map k v -> STM ()
delete k (Map h) = HAMT.focus Focus.deleteM k h

-- |
-- Delete all the associations.
{-# INLINE deleteAll #-}
deleteAll :: Map k v -> STM ()
deleteAll (Map h) = HAMT.deleteAll h

-- |
-- Focus on an item by a key with a strategy.
-- 
-- This function allows to perform composite operations in a single access
-- to a map item.
-- E.g., you can look up an item and delete it at the same time,
-- or update it and return the new value.
{-# INLINE focus #-}
focus :: (Eq k, Hashable k) => Focus.StrategyM STM v r -> k -> Map k v -> STM r
focus f k (Map h) = HAMT.focus f' k h
  where
    f' = (fmap . fmap . fmap) (\v -> k `seq` v `seq` (k, v)) . f . fmap associationValue

-- |
-- Construct a new map.
{-# INLINE new #-}
new :: STM (Map k v)
new = Map <$> HAMT.new

-- |
-- Construct a new map in IO.
-- 
-- This is useful for creating it on a top-level using 'unsafePerformIO', 
-- because using 'atomically' inside 'unsafePerformIO' isn't possible.
{-# INLINE newIO #-}
newIO :: IO (Map k v)
newIO = Map <$> HAMT.newIO

-- |
-- Check, whether the map is empty.
{-# INLINE null #-}
null :: Map k v -> STM Bool
null (Map h) = HAMT.null h

-- |
-- Get the number of elements.
{-# INLINE size #-}
size :: Map k v -> STM Int
size (Map h) = HAMTNodes.size h

-- |
-- Stream associations in a `MonadPlus` monad transformer. This will typically
-- be a "`ListT` done right" type, as provided by the `list-t`,
-- `list-transformer`, and `pipes` packages.
{-# INLINE stream #-}
stream :: (MonadTrans t, MonadPlus (t STM)) => Map k v -> t STM (k, v)
stream (Map h) = HAMT.stream h
