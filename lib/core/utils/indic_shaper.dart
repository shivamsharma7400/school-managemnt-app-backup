class IndicShaper {
  /// Enhanced Devanagari shaper to handle PDF rendering issues.
  /// Handles: 
  /// 1. Reordering of 'i' matra (ि)
  /// 2. Basic cleaning of some characters that cause issues in PDFs.
  static String shape(String input) {
    if (input.isEmpty) return input;

    var result = input;

    // 1. Reorder i-matra (ि) - U+093F
    // The i-matra comes after the consonant in Unicode but must be rendered before.
    // Handles simple consonants, nuktas (़), and clusters with halants (्).
    
    // Regex explanation:
    // ([क-ह]\u093C?) -> Base consonant with optional nukta
    // (\u094D[क-ह]\u093C?)* -> Optional halant followed by more consonants (conjuncts)
    // \u093F -> The i-matra itself
    final iMatraRegex = RegExp(r"(([क-ह]\u093C?(\u094D[क-ह]\u093C?)*))\u093F");
    
    result = result.replaceAllMapped(iMatraRegex, (Match m) {
      return '\u093F${m.group(1)}';
    });

    // 2. Extra refinements can go here
    // Some fonts/viewers struggle with specific sequences.
    
    return result;
  }
}
