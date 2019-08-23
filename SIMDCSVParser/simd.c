//
//  simd.c
//  simd
//
//  Created by Florian Kugler on 06-08-2019.
//  Copyright © 2019 Florian Kugler. All rights reserved.
//

#include "simd.h"

uint64_t cmp_mask_against_input(const uint8_t *ptr, uint8_t m) {
    const __m256i mask = _mm256_set1_epi8(m);
    __m256i lo = _mm256_loadu_si256((const __m256i *)(ptr + 0));
    __m256i hi = _mm256_loadu_si256((const __m256i *)(ptr + 32));
    __m256i cmp_res_0 = _mm256_cmpeq_epi8(lo, mask);
    uint64_t res_0 = (uint32_t)(_mm256_movemask_epi8(cmp_res_0));
    __m256i cmp_res_1 = _mm256_cmpeq_epi8(hi, mask);
    uint64_t res_1 = _mm256_movemask_epi8(cmp_res_1);
    return res_0 | (res_1 << 32);
}

uint64_t carryless_multiply(uint64_t x, uint64_t y) {
    // this creates a 2-element long long vector from a uint64_t by setting the upper half to zero
    __m128i a = _mm_set_epi64x(0ULL, x);
    __m128i b = _mm_set_epi64x(0ULL, y);
    // https://software.intel.com/sites/default/files/managed/72/cc/clmul-wp-rev-2.02-2014-04-20.pdf
    // last argument 0 means that bits 0:63 from the two 128 bit inputs will be used
    __m128i res = _mm_clmulepi64_si128(a, b, 0);
    return _mm_cvtsi128_si64(res);
}

