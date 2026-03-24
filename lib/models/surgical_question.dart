import 'package:isar/isar.dart';

// This line is needed for the database generator to work
part 'surgical_question.g.dart';

@collection
class SurgicalQuestion {
  Id id = Isar.autoIncrement; // Automatically numbers your questions

  @Index(type: IndexType.value)
  late String category; // e.g., "Upper GI", "Vascular", "Trauma"

  late String questionText;
  late List<String> options;
  late int correctOptionIndex;
  late String explanation;
  late String examLevel; // MRCS or FRCS
  
  // To remember which book this came from
  late String sourceBook;
}

