module cmd.suggestion;

import std.algorithm;
import std.string : stripLeft;

/**
 * Formats a hint naming the candidate closest to a mistyped name.
 *
 * Params:
 *   typed = Name that was not recognised.
 *   candidates = Names that would have been accepted.
 *
 * Returns:
 *   A hint such as `, did you mean 'serve'?`, or an empty string if no candidate is close enough.
 */
package string didYouMean(string typed, const(string)[] candidates) {
    string closest;
    size_t closestDistance = size_t.max;
    foreach (candidate; candidates) {
        const distance = levenshteinDistance(typed, candidate);
        if (distance < closestDistance) {
            closest = candidate;
            closestDistance = distance;
        }
    }
    if (closest is null || closestDistance > max(1, typed.stripLeft("-").length / 2))
        return "";
    return ", did you mean '" ~ closest ~ "'?";
}
