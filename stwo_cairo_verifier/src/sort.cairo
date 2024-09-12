use core::array::ToSpanTrait;
use core::array::ArrayTrait;
use core::option::OptionTrait;

trait Compare<T> {
    fn compare(self: @T, a: u32, b: u32) -> bool;
}

#[derive(Drop)]
pub struct LowerThan {}

impl LowerThanCompare of Compare<LowerThan> {
    fn compare(self: @LowerThan, a: u32, b: u32) -> bool {
        return a < b;
    }
}

#[derive(Drop)]
pub struct GreaterThan {}

impl GreaterThanCompare of Compare<GreaterThan> {
    fn compare(self: @GreaterThan, a: u32, b: u32) -> bool {
        return a > b;
    }
}

// Returns the element in `arr` that is nearest to `bound` according to the comparer criterion
pub fn iterate_sorted<T, +Compare<T>>(arr: Span<u32>, ref bound: Option<u32>, comparer: @T)
 -> Option<(u32, u32)> {
    let mut candidate_value = Option::None;
    let mut candidate_index = Option::None;

    let mut i = 0;
    while i < arr.len() {
        let bound_condition = if let Option::Some(bound) = bound {
            comparer.compare(bound, *arr[i])
        } else {
            true
        };
        let is_better_than_candidate = if let Option::Some(candidate_value) = candidate_value {
            comparer.compare(*arr[i], candidate_value)
        } else {
            true
        };
        if bound_condition && is_better_than_candidate {
            candidate_value = Option::Some(*arr[i]);
            candidate_index = Option::Some(i);
        }
        i += 1;
    };

    if(candidate_value.is_none()) {
        Option::None
    } else {
        bound = candidate_value;
        Option::Some((candidate_value.unwrap(), candidate_index.unwrap()))
    }
}

#[test]
fn test_sort_lowest_to_greatest() {
    let my_array = array![3, 5, 2, 4];
    let expected_array = array![2, 3, 4, 5];

    let mut sorted_array = array![];

    let mut bound = Option::None;
    while let Option::Some((value, _index)) = iterate_sorted(my_array.span(), ref bound, @LowerThan{}) {
        sorted_array.append(value);
    };

    assert_eq!(expected_array, sorted_array);
}

#[test]
fn test_sort_greatest_to_lowest() {
    let my_array = array![3, 5, 2, 4];
    let expected_array = array![5, 4, 3, 2];

    let mut sorted_array = array![];

    let mut bound = Option::None;
    while let Option::Some((value, _index)) = iterate_sorted(my_array.span(), ref bound, @GreaterThan{}) {
        sorted_array.append(value);
    };

    assert_eq!(expected_array, sorted_array);
}

#[test]
fn test_sort_indexes_are_correct() {
    let my_array = array![3, 5, 2, 4];
    let expected_indexes = array![2, 0, 3, 1];

    let mut sorted_indexes = array![];

    let mut bound = Option::None;
    while let Option::Some((value, index)) = iterate_sorted(my_array.span(), ref bound, @LowerThan{}) {
        sorted_indexes.append(index);
    };

    assert_eq!(expected_indexes, sorted_indexes);
}