class Cattle {
  final String id;
  final String tagNumber;
  final String? tagColour;
  final String? sex;
  final Map<String, dynamic>? breed;
  final DateTime? birthDate;
  final DateTime? weanDate;
  final double? weanWeight;
  final String? groupName;
  final String? campId;
  final String? farmId;
  final String? note;
  final String status;
  final String currentPregnancyStatus;

  Cattle({
    required this.id,
    required this.tagNumber,
    this.tagColour,
    this.sex,
    this.breed,
    this.birthDate,
    this.weanDate,
    this.weanWeight,
    this.groupName,
    this.campId,
    this.farmId,
    this.note,
    this.status = 'alive',
    this.currentPregnancyStatus = 'unknown',
  });

  factory Cattle.fromJson(Map<String, dynamic> json) => Cattle(
        id: json['id'] ?? '',
        tagNumber: json['tag_number'] ?? '',
        tagColour: json['tag_colour'],
        sex: json['sex'],
        breed: json['breed'],
        birthDate: json['birth_date'] != null
            ? DateTime.parse(json['birth_date'])
            : null,
        weanDate: json['wean_date'] != null
            ? DateTime.parse(json['wean_date'])
            : null,
        weanWeight: json['wean_weight']?.toDouble(),
        groupName: json['group_name'],
        campId: json['camp_id'],
        farmId: json['farm_id'],
        note: json['note'],
        status: json['status'] ?? 'alive',
        currentPregnancyStatus: json['current_pregnancy_status'] ?? 'unknown',
      );

  Map<String, dynamic> toJson() => {
        'tag_number': tagNumber,
        if (tagColour != null) 'tag_colour': tagColour,
        if (sex != null) 'sex': sex,
        if (breed != null) 'breed': breed,
        if (birthDate != null)
          'birth_date': birthDate!.toIso8601String().split('T')[0],
        if (weanDate != null)
          'wean_date': weanDate!.toIso8601String().split('T')[0],
        if (weanWeight != null) 'wean_weight': weanWeight,
        if (groupName != null) 'group_name': groupName,
        'note': note,
        'status': status,
        'current_pregnancy_status': currentPregnancyStatus,
      };
}
