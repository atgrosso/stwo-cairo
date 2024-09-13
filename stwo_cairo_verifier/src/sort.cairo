use core::array::ToSpanTrait;
use core::array::ArrayTrait;
use core::option::OptionTrait;

trait Compare<T, C> {
    fn compare(self: @C, a: T, b: T) -> bool;
}

#[derive(Drop, Copy)]
pub struct LowerThan {}

impl LowerThanCompare<T, +PartialOrd<T>> of Compare<T, LowerThan> {
    fn compare(self: @LowerThan, a: T, b: T) -> bool {
        return a < b;
    }
}

#[derive(Drop, Copy)]
pub struct GreaterThan {}

impl GreaterThanCompare<T, +PartialOrd<T>, +Copy<T>, +Drop<T>> of Compare<T, GreaterThan> {
    fn compare(self: @GreaterThan, a: T, b: T) -> bool {
        return a > b;
    }
}

#[derive(Drop)]
pub struct SortedIterator<T, C> {
    comparer: C,
    array: Span<T>,
    current_bound: Option<T>,
}

trait SortedIteratorTrait<T, C, +PartialOrd<T>, +Copy<T>, +Drop<T>, +Compare<T, C>, +Drop<C>, +Copy<C>> {
    fn iterate(array_to_iterate: Span<T>) -> SortedIterator<T, C>;

    fn next(ref self: SortedIterator<T, C>) -> Option<(T, u32)> {
        let mut candidate_value = Option::None;
        let mut candidate_index = Option::None;
    
        let mut i = 0;
        while i < self.array.len() {
            let bound_condition = if let Option::Some(current_bound) = self.current_bound {
                self.comparer.compare(current_bound, *self.array[i])
            } else {
                true
            };
            let is_better_than_candidate = if let Option::Some(candidate_value) = candidate_value {
                self.comparer.compare(*self.array[i], candidate_value)
            } else {
                true
            };
            if bound_condition && is_better_than_candidate {
                candidate_value = Option::Some(*self.array[i]);
                candidate_index = Option::Some(i);
            }
            i += 1;
        };
    
        if(candidate_value.is_none()) {
            Option::None
        } else {
            self.current_bound = candidate_value;
            Option::Some((candidate_value.unwrap(), candidate_index.unwrap()))
        }    
    }
}

pub impl MaximumToMinimumSortedIterator<T, +PartialOrd<T>, +Copy<T>, +Drop<T>> of SortedIteratorTrait<T, GreaterThan> {
    fn iterate(array_to_iterate: Span<T>) -> SortedIterator<T, GreaterThan> {
        SortedIterator { comparer: GreaterThan {}, array: array_to_iterate, current_bound: Option::None }
    }
}

pub impl MinimumToMaximumSortedIterator<T, +PartialOrd<T>, +Copy<T>, +Drop<T>> of SortedIteratorTrait<T, LowerThan> {
    fn iterate(array_to_iterate: Span<T>) -> SortedIterator<T, LowerThan> {
        SortedIterator { comparer: LowerThan {}, array: array_to_iterate, current_bound: Option::None }
    }
}


#[test]
fn test_sort_lowest_to_greatest() {
    let my_array: Array<u32> = array![3, 5, 2, 4];
    let expected_array: Array<u32> = array![2, 3, 4, 5];

    let mut sorted_array = array![];

    let mut iterator = MinimumToMaximumSortedIterator::iterate(my_array.span());
    while let Option::Some((value, _index)) = iterator.next() {
        sorted_array.append(value);
    };

    assert_eq!(expected_array, sorted_array);
}

#[test]
fn test_sort_greatest_to_lowest() {
    let my_array: Array<u32> = array![3, 5, 2, 4];
    let expected_array: Array<u32> = array![5, 4, 3, 2];

    let mut sorted_array = array![];

    let mut iterator = MaximumToMinimumSortedIterator::iterate(my_array.span());
    while let Option::Some((value, _index)) = iterator.next() {
        sorted_array.append(value);
    };

    assert_eq!(expected_array, sorted_array);
}

#[test]
fn test_sort_indexes_are_correct() {
    let my_array: Array<u32> = array![3, 5, 2, 4];
    let expected_indexes: Array<u32> = array![2, 0, 3, 1];

    let mut sorted_indexes = array![];

    let mut iterator = MinimumToMaximumSortedIterator::iterate(my_array.span());
    while let Option::Some((_value, index)) = iterator.next() {
        sorted_indexes.append(index);
    };

    assert_eq!(expected_indexes, sorted_indexes);
}
