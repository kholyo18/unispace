import 'package:flutter/material.dart';
import 'package:UniSpace/generated/l10n.dart';

class ProgramComponent {
  final String label; // TD / TP / EXAM / CC...
  final double weight; // نسبة مئوية 0..100
  const ProgramComponent(this.label, this.weight);
}

class ProgramModule {
  final String name;
  final int coef;
  final int credits;
  final List<ProgramComponent> components;

  const ProgramModule({
    required this.name,
    required this.coef,
    required this.credits,
    required this.components,
  });
}

class ProgramTrack {
  final String name; // L1 / L2 / L3 specialization
  final String level;
  final List<ProgramSemester> semesters;

  const ProgramTrack({
    required this.name,
    required this.level,
    required this.semesters,
  });
}

class ProgramSemester {
  final String label; // S1 / S2
  final List<ProgramUnit> unit;

  const ProgramSemester({
    required this.label,
    required this.unit,
  });
}

class ProgramUnit {
  final String label;
  final List<ProgramModule> modules;
  const ProgramUnit({
    required this.label,
    required this.modules,
  });
}

class ProgramMajor {
  final String name; // التخصص

  final List<ProgramTrack> tracks;

  const ProgramMajor({
    required this.name,
    required this.tracks,
  });
}

class ProgramFaculty {
  final String name; // الكلية
  final List<ProgramMajor> majors;

  const ProgramFaculty({
    required this.name,
    required this.majors,
  });
}

List<ProgramFaculty> getDemoFaculties(BuildContext context) {
  return [
    ProgramFaculty(name: S.of(context).facultyLawPolitical, majors: [
      // ===========================
      // السنة 1 – قسم التعليم الأساسي
      // ===========================
      ProgramMajor(
        name: S.of(context).politicalSciences,
        tracks: [
          ProgramTrack(
            name: S.of(context).commonCore,
            level: 'Licence 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'مدخل لعلم السياسة 1',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تاريخ الفكر السياسي 1',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'اقتصاد سياسي',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية البحث في العلوم السياسية 1',
                    coef: 3,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'تاريخ الجزائر السياسي 1',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'الهوية والمواطنة',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'مدخل للعلوم القانونية',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name: 'لغة اجنبية 1',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'مدخل لعلم السياسة 2',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'تاريخ الفكر السياسي 2',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'اقتصاديات التنمية',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    )
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'منهجية البحث في العلوم السياسية 2',
                      coef: 3,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    )
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'تاريخ الجزائر السياسي 2',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name: 'البرمجة',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    )
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'مدخل لعلم الاجتماع',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name: 'إنجليزية 2',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          ProgramTrack(
            name: S.of(context).commonCore,
            level: 'Licence 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'مدخل لعلم الادارة',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'مدخل للعلاقات الدولية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'نظم سياسية مقارنة 1',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'تقنيات البحث العلمي',
                    coef: 3,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'نظرية الدولة',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'الدولة والمجتمع المدني/الحقوق والحريات الاساسية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'مدخل الى الاحصاء',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name: 'لغة اجنبية ',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'نظرية التنظيم والتسيير',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'نظرية العلاقات الدوية ',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'نظم سياسية مقارنة 2',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    )
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'تحليل الخطاب السياسي',
                      coef: 3,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    )
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: ' المؤسسات السياسية والادارية في الجزائر',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name:
                          'الجغرافيا السياسية/الاحزاب السياسية والنظم الانتخابية',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    )
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'نظريات وسياسات التنمية',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name: 'إنجليزية ',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          ProgramTrack(
            name: S.of(context).politicalAdministrativeOrgs,
            level: 'Licence 3',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'تسيير الوارد البشرية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاتجاهات الحديثة في التسيير',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الادارة العامة المقارنة',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'تحرير اداري 1',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'مقاولاتية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name:
                        'الاصلاح السياسي والاداري في الجزائر/ السياسات البيئية والتعمير',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'الادارة الالكترونية',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name: 'انجليزية ',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'الوظيفة العمومية',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ادارة الجودة والتمييز',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'نظريات التنظيم والتسيير',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    )
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'تحرير اداري 2',
                      coef: 3,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    )
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'التشريع في الجزائر',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name: 'الديموقراطية وحقوق الانسان/الحريات العامة',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    )
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'اداب واحلاقيات المهنة',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name: 'إنجليزية ',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
        ],
      ),
      ProgramMajor(
        name: S.of(context).law,
        tracks: [
          //=========ليسونس=========
          ProgramTrack(
            name: S.of(context).commonCore,
            level: 'Licence 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'مدخل للقانون 1',
                    coef: 2,
                    credits: 7,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون ديستوري 1',
                    coef: 2,
                    credits: 7,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تنظيم قضائي 1',
                    coef: 1,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية العلوم القانونية 1',
                    coef: 1,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'تاريخ النظم القانونية',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'المجتمع الدولي',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'انجليزية',
                      coef: 1,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(label: 'S2', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'مدخل للقانون 2',
                    coef: 2,
                    credits: 7,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون دستوري 2',
                    coef: 2,
                    credits: 7,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تنظيم قضائي 2',
                    coef: 1,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية العلوم القانوية 2',
                    coef: 1,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'مدخل للشريعة الاسلامية',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'اقتصاد سياسي',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                  ProgramModule(
                    name: 'إنجليزية',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ])
              ]),
            ],
          ),

          ProgramTrack(
            name: S.of(context).commonCore,
            level: 'Licence 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'قانون مدني 1',
                    coef: 2,
                    credits: 7,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون جنائي عام',
                    coef: 2,
                    credits: 7,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون اداري 1',
                    coef: 1,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'تقنيات البحث العلمي 1',
                    coef: 1,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون دولي عام',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون تجاري',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'انجليزية',
                      coef: 1,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'قانون مدني 2',
                      coef: 2,
                      credits: 7,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'قانون الاجراءات الجنائية',
                      coef: 2,
                      credits: 7,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'قانون اداري 2',
                      coef: 1,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    )
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'تقنيات البحث العلمي 2',
                      coef: 1,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    )
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'حقوق الانسان',
                      coef: 1,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name: 'قانون العمل',
                      coef: 1,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    )
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'إنجليزية',
                      coef: 1,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),

          ProgramTrack(
            name: S.of(context).publicLaw,
            level: 'Licence 3',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'قرارات وعقود ادارية',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الوظيفة العمومية',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'حريات وحقوق اساسية',
                    coef: 1,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'قانون مقارن',
                    coef: 1,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون دبلوماسي وقنصلي',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون دولي انساني',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'مقاولاتية',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'المقاولاتية',
                      coef: 1,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(label: 'S2', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'المنازعات الادارية',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون الاقتصاد العام',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الحريات العامة',
                    coef: 1,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'الاخلاق والسلوك المهني',
                    coef: 1,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'القانون الجنائي الخاص',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'القانون الجنائي الدولي',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون الضرائب',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'انجليزية',
                      coef: 1,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ],
                )
              ])
            ],
          ),

          ProgramTrack(
            name: S.of(context).privateLaw,
            level: 'Licence 3',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'عقود خاصة 1',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'شركات تجارية',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون دولي خاص 1',
                    coef: 1,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'قانون مقارن',
                    coef: 1,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون جنائي خاص وجرائم الفساد',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'مقاولاتية',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'طرق الاثبات والتنفيد',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'انجليزية',
                      coef: 1,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(label: 'S2', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'عقود خاصة 2',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاوراق التجارية والافلاس',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون دولي خاص 2',
                    coef: 1,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'اداب واخلاقيات المهنة',
                    coef: 1,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون الملكية الفكرية',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون التامين',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون بحري',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'انجليزية',
                      coef: 1,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ],
                )
              ])
            ],
          ),

          //==========ماستر=========
          ProgramTrack(
            name: S.of(context).advancedPublicLaw,
            level: 'Master 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'النظم السياسية الديمقراطية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون المرافق العامة',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'سلطات الضبط المستقلة',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية البحث العلمي 1',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'التحرير الاداري و القضائي',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون الميزانية',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'حقوق الانسان',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(label: 'S2', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'المؤسسات الدستورية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'اللامركزية والجمهورية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'المسؤولية الادارية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية البحث العلمي 2',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تكنلوجيا الاعلام والاتصال',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'التنظيم القضائي',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'منازعات الصفقات العمومية',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبيةة 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ])
            ],
          ),
          ProgramTrack(
            name: S.of(context).advancedPublicLaw,
            level: 'Master 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'الاحزاب السياسية والقانون الانتخابي',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'المنازعات الدستورية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاجراءات القضائية الادارية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية اعداد المندكرة',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'المشروع المهني والشخصي',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'النام التاديبي للموظف العمومي',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'جرائم الفساد',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 3',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),
            ],
          ),

          ProgramTrack(
            name: S.of(context).familyLaw,
            level: 'Master 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'عقد الزواج واثاره',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'علم الفرائض 1',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'طرق الاثبات في قانون الاسرة',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية البحث العلمي 1',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'منهجية التحرير الاداري و القضائي',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون الحالة المدنية',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'علم الاجتماع الاسري',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(label: 'S2', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'انحلال الرابطة الزوجية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'احكام الفرائض 2',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الحماية الجزائية للاسرة',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية البحث العلمي 2',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تكنلوجيا الاعلام والاتصال',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'المقاصد العامة لاحكام الاسرة',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'قضايا الاسرة في القانون الدولي',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ])
            ],
          ),
          ProgramTrack(
            name: S.of(context).familyLaw,
            level: 'Master 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'تنازع القوانين في مسائل الاسرة',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'دعاوى شؤون الاسرة',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'التبرعات',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية اعداد المندكرة',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'المشروع المهني والشخصي',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'الحماية المؤسساتية للاسرة و الطفولة',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'النيابة الشرعية',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 3',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),
            ],
          ),
//////////////////////////////////////////////////////////////
          ProgramTrack(
            name: S.of(context).criminalLaw,
            level: 'Master 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'القانون الجنائي الخاص 1',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون الاجراءات الجنائية المعمق',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'المسؤولية الجنائية 1',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية البحث العلمي 1',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تقنيات تحرير العرائض',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'علم الاجرام المعمق',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'القانون الجنائي المقارن',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(label: 'S2', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'القانون الجنائي الخاص 2',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاثبات الجنائي',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'المسؤولية الجنائية 2',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية البحث العلمي 2',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تكنلوجيا الاعلام والاتصال',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'العدالة الجنائية الدولية',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'الانظمة العقابية البديلة',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ])
            ],
          ),
          ProgramTrack(
            name: S.of(context).criminalLaw,
            level: 'Master 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'قضاء الاحداث',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'القانون الجنائي للاعمال',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون تنظيم المؤسسات العقابية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية اعداد المندكرة',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'المشروع المهني والشخصي',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'جرائم الفساد ومكافحته',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'الجريمة الجمركية',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 3',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),
            ],
          ),
/////////////////////////////////////////////////////////////////////////////////////////////
          ProgramTrack(
            name: S.of(context).businessLaw,
            level: 'Master 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'عقود الاعمال',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'شركات الاموال',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون الاستثمار',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية البحث العلمي 1',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تحرير العقود والعرائض',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون التامين',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون الجمارك',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(label: 'S2', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'قانون التجارة الخارجية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'القانون البنكي',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون الاسواق المالية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية البحث العلمي 2',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تكنلوجيا الاعلام والاتصال',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'القانون البحري',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون البيئة',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ])
            ],
          ),
          ProgramTrack(
            name: S.of(context).businessLaw,
            level: 'Master 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'قانون المنافسة',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون الاستهلاك',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'القانون الجنائي للاعمال',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية اعداد المندكرة',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'المشروع المهني والشخصي',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'القانون الجبائي',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون الدفع الالكتروني',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 3',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),
            ],
          ),
          //////////////////////////////////////////////////////////////////
          ProgramTrack(
            name: S.of(context).legalProfessionsLaw,
            level: 'Master 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'تطبيقات العقود',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تطبيقات الدعاوى المدنية والادارية 1',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تطبيقات الاجراءات الجزائية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية البحث العلمي 1',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'منهجية الممارسة المهنية',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'اخلاقيات المهن القضائية',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'التحكيم التجاري الدولي',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(label: 'S2', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'المسؤولية المهنية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تطبيقات الدعاوى الاجرائية 2',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'التركات والمواريث',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية البحث العلمي 2',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تكنلوجيا الاعلام والاتصال',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'القانون الدولي الخاص',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'تطبيقات التنفيد والبيوع القضائية',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ])
            ],
          ),
          ProgramTrack(
            name: S.of(context).legalProfessionsLaw,
            level: 'Master 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'الطرق البديلة لتسوية النزاعات',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تطبيق علاقات العمل والمنازعات الاجتماعية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'التسيير القانوني للشركات',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية اعداد المندكرة',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'المشروع المهني والشخصي',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'تقنيات البنوك والتامينات',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'مكافحة الفساد واخلاقيات المهن',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 3',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),
            ],
          ),
          /////////////////////////////////////////////////
          ProgramTrack(
            name: S.of(context).maritimePortLaw,
            level: 'Master 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'القانون الحري المعمق',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'النظام القانوني للحقوق البحرية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون الملاحة البحرية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'تكنولوجيا الاعلام والاتصال',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاعلام الالي 1',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'رجال البحر',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'المنظمات الدولية البحرية',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(label: 'S2', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'وسائل وانظمة الدفع',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'عقد النقل البحري للضائع',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون التجارة الخارجية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'تحرير عقود النقل البحري للبضائع',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاعلام الالي 2 ',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'التصادم البحري',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون حماية البيئة البحرية',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ])
            ],
          ),
          ProgramTrack(
            name: S.of(context).maritimePortLaw,
            level: 'Master 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'قانون الادارة المينائية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'المنازعات البحرية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'التامين البحري',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'الاعلام الالي 3',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'المشروع المهني والشخصي',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون الجمارك',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'القانون الدولي للبحار',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 3',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),
            ],
          ),
          ////////////////////////////////////////////////////////
          ProgramTrack(
            name: S.of(context).energyMiningLaw,
            level: 'Master 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'قانون الطاقة والطاقة المتجددة',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون المناجم',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون الاملاك الوطنية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'تكنولوجيا الاعلام والاتصال',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاعلام الالي ',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون المنافسة',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'منازعات العمل',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(label: 'S2', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'العقود الطاقوية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'السندات والرخص لمنجمية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'مؤسسات الطاقة والمنجم',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'ابرام وتحرير عقود الطاقة',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تحرير الاتفاقيات المنجمية ',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'منظمات الطاقة الدولية',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون الاستثمار',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ])
            ],
          ),
          ProgramTrack(
            name: S.of(context).energyMiningLaw,
            level: 'Master 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'وكالتا الضبط في قطاع الطاقة والمناجم',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'قانون التجارة الدولية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الجباية في المجال الطاقوي والمنجمي',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية اعداد مدكرة التخرج',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'المشروع المهني والشخصي',
                    coef: 1,
                    credits: 3,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون حماية البيئة والامن الصناعي',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'اليات تسوية النزاعات الطاقوية والمنجمية',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 3',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),
            ],
          ),
          //////////////////////////////////////////////////////////////////
          ProgramTrack(
            name: S.of(context).taxLaw,
            level: 'Master 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'مدخل للقانون الجبائي',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الضرائب المباشرة وغير المباشرة',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تاسيس وتحصيل الجباية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'تحرير الوثائق الجبائية',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون الاستثمار',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'الميزانية العامة',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'البرمجة ',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name: 'انجليزية',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(label: 'S2', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'الرقابة الجبائية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'جباية المحروقات',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الجباية الايكولوجية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية البحث العلمي',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون مكافحة الفساد',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'جمركة السلع والبضائع',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'الدكاء الاصطناعي',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name: 'لغة اجنبية 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ])
            ],
          ),
          ProgramTrack(
            name: S.of(context).taxLaw,
            level: 'Master 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'الاثبات الجنائي الجبائي',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'اليات تسوية المنازعات الجبائية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'التهرب والغش الجبائي',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'منهجية اعداد مدكرة التخرج',
                    coef: 2,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'الجريمة الجمركية',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'مجلس المحاسبة',
                    coef: 1,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'البرمجيات الحرة والمصادر المفتوحة',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name: 'لغة اجنبية 3',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),
            ],
          ),
        ],
      )
    ]),
    ProgramFaculty(name: S.of(context).facultyEconomics, majors: [
      // ===========================
      // السنة 1 – قسم التعليم الأساسي
      // ===========================
      ProgramMajor(
        name: S.of(context).basicEducationDept,
        tracks: [
          ProgramTrack(
            name: S.of(context).basicEducation,
            level: 'Licence 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'محاسبة مالية1',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'مدخل الاقتصاد',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'اقتصاد جزئي 1',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'احصاء1',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'رياضيات 1',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'مدخل لعلم اجتماع المنظمات',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'مدخل للقانون',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'مدخل للبايثون',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية 1',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'اقتصاد المؤسسة',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'محاسبة مالية 2',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'تاريخ الفكر الاجتماعي',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'اقتصاد جزئي 2',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'احصاء2',
                      coef: 3,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'رياضيات 2',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'قانون تجاري',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name: 'إعلام آلي 1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'إنجليزية 2',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          ProgramTrack(
            name: S.of(context).commonCore,
            level: 'Licence 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'مدخل لعلم الادارة',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'مدخل للعلاقات الدولية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'نظم سياسية مقارنة 1',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'تقنيات البحث العلمي',
                    coef: 3,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'نظرية الدولة',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'الدولة والمجنمع المدني/الحقوق والحريات الاساسية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'مدخل الى الاحصاء',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name: 'لغة اجنبية ',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'نظرية التنظيم والتسيير',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'نظرية العلاقات الدوية ',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'نظم سياسية مقارنة 2',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    )
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'تحليل الخطاب السياسي',
                      coef: 3,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    )
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: ' المؤسسات السياسية والادارية في الجزائر',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name:
                          'الجغرافيا السياسية/الاحزاب السياسية والنظم الانتخابية',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    )
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'نظريات وسياسات التنمية',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name: 'إنجليزية ',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          ProgramTrack(
            name: 'تنظيمات ساسية وادارية',
            level: 'Licence 3',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'تسيير الوارد البشرية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاتجاهات الحديثة في التسيير',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الادارة العامة المقارنة',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'تحرير اداري 1',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  )
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'مقاولاتية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name:
                        'الاصلاح السياسي والاداري في الجزائر/ السياسات البيئية والتعمير',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  )
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'الادارة الالكترونية',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name: 'انجليزية ',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'الوظيفة العمومية',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ادارة الجودة والتمييز',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'نظريات التنظيم والتسيير',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    )
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'تحرير اداري 2',
                      coef: 3,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    )
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'التشريع في الجزائر',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name: 'الديموقراطية وحقوق الانسان/الحريات العامة',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    )
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'اداب واحلاقيات المهنة',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                    ProgramModule(
                      name: 'إنجليزية ',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
        ],
      ),
      // ============================================
      //  قسم علوم التسيير
      // ============================================
      ProgramMajor(
        name: S.of(context).managementSciencesDept,
        tracks: [
          // ============================================
          // السنة 2 – قسم علوم التسيير
          // ============================================
          ProgramTrack(
            name: S.of(context).managementSciences,
            level: 'Licence 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'محاسبة تسيير',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'اقتصاد كلي 1',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'مدخل لادارة الاعمال',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'مالية عمومية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'احصاء 3',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'رياضيات مالية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                  ProgramModule(
                    name: 'اقتصاد نقدي',
                    coef: 1,
                    credits: 1,
                    components: [
                      //ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'المنهجية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'اعلام آلي 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'نظم المعلومات الإدارية',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'اقتصاد كلي 2',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'تسيير المؤسسة',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'التسويق',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'احصاء4',
                      coef: 3,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'أساسيات بحوث العمليات',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'ريادة الأعمال',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                    ProgramModule(
                      name: 'أخلاقيات الأعمال',
                      coef: 1,
                      credits: 1,
                      components: [
                        //ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'لغة أجنبية 3',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          // //========================================================
          // //===============السنة الثالثة ادارة اعمال===============
          ProgramTrack(
            name: S.of(context).businessAdministration,
            level: 'Licence 3',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'هياكل وتنظيم المؤسسات',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة تكنلوجيا المعلومات',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة المشاريع',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة الموارد البشرية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'ادارة مالية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تقنيات الاستقصاء',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: S.of(context).businessLaw,
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'ادارة استراتيجية',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ادارة الانتاج والعمليات',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ادارة الجودة الشاملة',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ادارة سلسلة الامداد',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'مراقبة التسيير',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'مشروع التخرج',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'تحليل البيانات',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          // //========================================================
          // //===============السنة الثالثة ادارة مالية===============
          ProgramTrack(
            name: S.of(context).financialManagement,
            level: 'Licence 3',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'الادارة المالية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة المشاريع',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تقنيات الميزانية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'النظرية المالية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'ادارة الموارد البشرية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تقنيات الاستقصاء',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: S.of(context).businessLaw,
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'ادارة استراتيجية',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'التدقيق المالي',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'مراقبة التسيير',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ادارة مصادر التمويل',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'جباية المؤسسة',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'مشروع التخرج',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'تحليل البيانات',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          // //========================================================
          // //===============السنة الثالثة ادارة موارد بشرية===============
          ProgramTrack(
            name: S.of(context).humanResourcesManagement,
            level: 'Licence 3',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'اسس ادارة الموارد البشرية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة المسارات المهنية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاتصال التنظيمي',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الادارة الاستراتيجية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'ادراة تكنولوجيا المعلومات',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تقنيات الاستقصاء',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون العمل',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),
              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'ادارة استراتيجية للموارد البشرية',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'هندسة التكوين',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ادارة الكترونية للموارد البشرية',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'الصحة والسلامة المهنية',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'مراقبة التسيير',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'مشروع التخرج',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'تحليل البيانات',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          // //========================================================
          // //===============السنة الرابعة ادارة اعمال===============
          ProgramTrack(
            name: S.of(context).businessAdministration,
            level: 'Master 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'تحليل الاستراتيجي والتنافسي',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'السلوك التنظيمي',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة الاعمال الدولية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ثقافة المنظمة',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'ادارة المعرفة',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاتصال والتحرير الاداري',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'تطبيقات التعلم العميق',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'ك.ع.خ.اع. بالغة الانجليزية',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ],
                )
              ]),
              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'نظرية المنظمة',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'تخطيط موارد المؤسسة ERP',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ادارة الابداع والابتكار',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'دكاء الاعمال وتنافسية المنظمات',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'الاساليب لكمية في الادارة',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'منهجية اعداد مدكر الماستر',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'التسويق الاستراتيجي',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'لغ.انج. للابحاث وكتابة المدكرات',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          // //========================================================
          // //===============السنة الخامسة ادارة اعمال===============

          ProgramTrack(
            name: S.of(context).businessAdministration,
            level: 'Master 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'ادارة الاداء والتميز',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة استراتيجية للموارد البشرية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'القيادة الادارية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة مشاريع الكترونية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'برمجيات احصائية حرة',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة التعاقد والتفاوض',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون المنافسة وحماية المستهلك',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'ندوة في ادارة الاعمال',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ],
                )
              ]),
            ],
          ),
          // //========================================================
          // //===============السنة الرابعة ادارة  مالية===============
          ProgramTrack(
            name: S.of(context).financialManagement,
            level: 'Master 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: ' الادارة الماليةالمتقدمة',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الهندسة المالية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'التخطيط والرقابة المالية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الادارة الالكترونية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'محاسبة الشركات',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاتصال والتحرير الاداري',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'تحليل السلاسل الزمنية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'ك.ع.خ.اع. بالغة الانجليزية',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ],
                )
              ]),
              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'الادارة المالية الدولية',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ادارة المحفظة المالية',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ادارة المرافق العمومية',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ادارة الابداع والابتكار',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'الاساليب الكمية في الادارة',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'منهجيةاعداد مدكرة الماستر',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'قانون الصفقات العمومية',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'لغ.انج. للابحاث وكتابة المدكرات',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          // //========================================================
          // //===============السنة الخامسة ادارة  مالية===============

          ProgramTrack(
            name: S.of(context).financialManagement,
            level: 'Master 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'ادارة المؤسسات المالية والتمويل',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة المخاطر المالية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'عمليات الخزينة',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'برمجيات احصائية حرة',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تكنلوجيا مالية والدكاء الاصطناعي',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'التمويل الاسلامي',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'ندوة في الادارة المالية',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ],
                )
              ]),
            ],
          ),
          // //========================================================
          // //===============السنة الرابعة ادارة موارد بشرية===============
          ProgramTrack(
            name: S.of(context).humanResourcesManagement,
            level: 'Master 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'الهندسة الوظيفية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'السلوك التنظيمي',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ثقافة المنظمة',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة الاجور والحوافز 1',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'مراقبة التسيير الاجتماعي',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاتصال والتحرير الاداري',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'تطبيقات التعلم العميق',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'ك.ع.خ.اع. بالغة الانجليزية',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ],
                )
              ]),
              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'نظرية المنظمة',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ادارة المعرفة',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'تخطيط موارد المؤسسة ERP',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ادارة الاجور والحوافز 2',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'الاساليب الكمية في الادارة',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'منهجية اعداد مدكرة الماستار',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'التدقيق الاجتماعي',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'لغ.انج. للابحاث وكتابة المدكرات',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          // //========================================================
          // //===============السنة الخامسة ادارة موارد بشرية===============

          ProgramTrack(
            name: S.of(context).humanResourcesManagement,
            level: 'Master 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'ادارة المخاطر الاجتاعية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة التغيير',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'القيادة الادارية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'برمجيات احصائية حرة',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة الكفاءات',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون الاساسي للوظيفة العمومية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'ندوة حول ادارة الموارد البشرية',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ],
                )
              ]),
            ],
          ),
          // //========================================================
          // //===============السنة الرابعة التسيير المالي للمؤسسات===============
          ProgramTrack(
            name: S.of(context).corporateFinancialManagement,
            level: 'Master 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'التسيير المالي المعمق',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'التشخيص المالي للمؤسسات',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'دراسة وتقييم المشاريع الاستثمارية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'المقاولاتية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'التسيير الجبائي للمؤسسة',
                    coef: 3,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون مكافحة الفساد',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'انجليزية مهنية',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ],
                )
              ]),
              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'التخطيط المالي',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'محاسبة الشركات',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'الهندسة المالية',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'منهجية البحث العلمي',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'الرقابة الجائية والمنازعات',
                      coef: 3,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: S.of(context).businessLaw,
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'انجليزية مهنية',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          // //========================================================
          // //===============السنة الخامسة التسيير المالي للمؤسسات===============

          ProgramTrack(
            name: S.of(context).corporateFinancialManagement,
            level: 'Master 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'ادارة التدفقات المالية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الادارة الاستراتيجية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تسيير المحفظة المالية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'الاتصال والتحرير الاداري',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'حوكمة الشركات',
                    coef: 3,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون الصفقات العمومية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'انجليزية مهنية',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ],
                )
              ]),
            ],
          ),
        ],
      ),
      // ============================================
      //  قسم علوم تجارية
      // ============================================
      ProgramMajor(
        name: S.of(context).commercialSciencesDept,
        tracks: [
          // ============================================
          // السنة 2 – قسم علوم التسيير
          // ============================================
          ProgramTrack(
            name: S.of(context).commercialSciences,
            level: 'Licence 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'محاسبة تسيير',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'اساسيات التسويق 1',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'اقتصاد كلي 1',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'مدخل لادارة الاعمال',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'احصاء3',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'رياضيات مالية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'اقتصاد نقدي',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'المنهجية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'اعلام آلي 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(label: 'S2', unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'مالية وتجارة دولية',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'اساسيات التسويق 2',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'اقتصاد كلي 2 ',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'تسيير المؤسسة',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'احصاء4',
                      coef: 3,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'أساسيات بحوث العمليات',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'ريادة الأعمال',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                    ProgramModule(
                      name: 'أخلاقيات الأعمال',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'لغة أجنبية 3',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          // //========================================================
          // //===============السنة الثالثة مالية وتجارة دولية===============
          ProgramTrack(
            name: S.of(context).financeInternationalTrade,
            level: 'Licence 3',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'نظريات التجارة الدولية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تقنيات التجارة الدولية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة الاعمال الدولية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'استراتيجيات الشركات متعددة الجنسيات',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'الجغرافيا الاقتصادية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تحليل البيانات',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون التجارة الدولية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'السياسات التجارية الدولية',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'التجارة الالكترونية',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'التسويق الدولي',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'مالية دولية',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'اقتصاد قياسي',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'مشروع التخرج',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'برمجيات احصائية 1',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          // //========================================================
// //===============السنة الثالثة تسويق===============
          ProgramTrack(
            name: S.of(context).marketing,
            level: 'Licence 3',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'سلوك المستهلك',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'بحوث التسويق 1',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاتصالات التسويقية المتكاملة',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تسويق الخدمات',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'التسويق الرقمي',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تحليل البيانات التسويقية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون المنافسة وحماية المستهلك',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'التسويق العملياتي',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'بحوث التسويق 2',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'التسويق الاستراتيجي',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'التسويق الدولي',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'التفاوض التجاري',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'مشروع التخرج',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'برمجيات احصائية 1',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),

          // //========================================================
// //===============السنة الرابعة تسويق الخدمات===============
          ProgramTrack(
            name: S.of(context).servicesMarketing,
            level: 'Master 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'التحليل الاستراتيجي والتنافسي',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة المبيعات والقوى البيعية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة الخدمات',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة العلامة التجارية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'الاساليب الكميية في التسويق 1',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاتصال والتحرير الاداري',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'تطبيقات في التسويق الرقمي',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة 1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),
              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'ابتكار وتطوير الخدمات',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ادارة جودة الخدمات',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'تسويق الخدمات المالية',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ادارة علاقات العملاء',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'الاساليب الكمية في التويق 2',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'منهجية اعداد مدكر الماستر',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'تسويق الخدمات العمومية',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          // //========================================================
// //===============السنة الخامسة تسويق الخدمات===============

          ProgramTrack(
            name: S.of(context).servicesMarketing,
            level: 'Master 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'تسويق الخدمات الصحية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تسويق خدمات النقل',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'التسويق السياحي والفندقي',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'برمجيات احصائية 2',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الرقابة التسويقية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: S.of(context).businessLaw,
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'ندوة في تسويق الخدمات',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),
            ],
          ),
          // //========================================================
// //===============السنة الرابعة  تسويق فندقي وسياحي===============
          ProgramTrack(
            name: S.of(context).hotelTourismMarketing,
            level: 'Master 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: ' ادارة الخدمات السياحية والفندقية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'التسويق السياحي',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'التسويق الفندقي',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'سلوك المستهلك السياحي',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'الاساليب الكمية في التسويق 1',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاتصال والتحرير الاداري',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'القانون السياحي والفندقي',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة 1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),
              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'ادارة جودة الخدمات السياحية',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'الاتصال التسويقي السياحي',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ادارة العلامة التجارية',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ادارة علاقات العملاء',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'الجغرافيا السياحية',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'منهجية اعداد مدكرة الماستر',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'الاساليب الكمية في التسويق 2',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          // //========================================================
// //===============السنة الخامسة تسويق فندقي وسياحي===============

          ProgramTrack(
            name: S.of(context).hotelTourismMarketing,
            level: 'Master 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'التحليل الاستراتيجي والتنافسي',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة الاحداث والوجهات السياحية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة الموارد البشرية السياحية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'برمجيات احصائية 2',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ادارة شركات والوكالات السياحية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'برمجيات التسويق السياحي الالكتروني',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'ندوة في التسويق الياحي والفندقي',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),
            ],
          ),


        ],
      ),
      // ============================================
      //  قسم علوم مالية ومحاسبة
      // ============================================
      ProgramMajor(
        name: S.of(context).financialAccountingDept,
        tracks: [
          // ============================================
          // السنة 2 – علوم مالية ومحاسبة
          // ============================================
          ProgramTrack(
            name: S.of(context).financialAccounting,
            level: 'Licence 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'محاسبة تسيير',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'مالية عمومية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'اقتصاد كلي 1',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'اقتصاد نقدي',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'احصاء3',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'رياضيات مالية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'مدخل لادارة الاعمال',
                    coef: 1,
                    credits: 1,
                    components: [
                      //ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'المنهجية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'اعلام آلي 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(label: 'S2', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'مالية المؤسسة',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'المعايير المحاسبية الدولية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'اقتصاد كلي 2 ',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تسيير المؤسسة',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'احصاء4',
                    coef: 3,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'أساسيات بحوث العمليات',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'ريادة الأعمال',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  ),
                  ProgramModule(
                    name: 'أخلاقيات الأعمال',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                  ProgramModule(
                    name: 'لغة أجنبية 3',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ])
              ],
              )
            ],
          ),
          // //========================================================
          // //===============السنة الثالثة مالية ===============
          ProgramTrack(
            name: S.of(context).finance,
            level: 'Licence 3',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'التسيير المالي 1',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'المحاسبة المالية المعمقة 1',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'اسواق مالية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'جباية المؤسسة',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'مراقبة التسيير',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تقنيات بنكية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: S.of(context).businessLaw,
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'التسيير المالي 2',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'المحاسبة المالية المعمقة 2',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'النظرية المالية',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'تجارة ومالية دولية',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'تقييم المشاريع',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'مشروع التخرج',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'تحليل البيانات',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          // //========================================================
// //===============السنة الثالثة محاسبة===============
          ProgramTrack(
            name: S.of(context).accounting,
            level: 'Licence 3',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'المحاسبة المالية المعمقة 1',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'جباية المؤسسة 1',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'نظرية المحاسبة',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'محاسبة الشركات',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'التسيير المالي',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تقنيات الاستقصاء',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون الشركات',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'محاسبة مالية معمقة 2',
                      coef: 3,
                      credits: 6,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'جباية المؤسسة 2',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'تدقيق محاسبي',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'مراقبة التسيير',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'محاسبة عمومية',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'مشروع التخرج',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'تحليل البيانات',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),

          // //========================================================
// //===============السنة الرابعة محاسبة وجباية===============
          ProgramTrack(
            name: S.of(context).accountingTaxation,
            level: 'Master 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'التسيير المالي المعمق',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الجباية المعمقة 1',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'معايير اعدات التقارير المالية الدولية IFRS1',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'محاسبة الشركات المعمقة 1',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'حوكمة لشركات',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاتصال والتحرير الاداري',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'النمدجة الاحصائية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة 1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),
              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'المحاسبة القطاعية 1',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'الجباية المعمقة 2',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'معايي اعداد التقارير الماية الدولة IFRS2',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'محاسبة الشركات المعمقة 2',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'تنظيم واخلاقيات مهنة المحاسبة',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'منهجية اعداد مدكر الماستر',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'برمجيات احصائية',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          // //========================================================
// //===============السنة الخامسة  محاسبة وجباية===============

          ProgramTrack(
            name: S.of(context).accountingTaxation,
            level: 'Master 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'المحاسبة القطاعية 2',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الرقابة والتدقيق الجبائي',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'مراقبة التسيير المعمقة',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'الجباية الدولية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'حوكمة الشركات',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'القانون الجزائي للاعمال',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'ندوة في الجباية',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ],
                )
              ]),
            ],
          ),



        ],
      ),
      // ============================================
      //  قسم علوم اقتصادية
      // ============================================
      ProgramMajor(
        name: S.of(context).economicsDept,
        tracks: [
          // ============================================
          // السنة 2 – علوم اقتصادية
          // ============================================
          ProgramTrack(
            name: S.of(context).economics,
            level: 'Licence 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'اقتصاد كلي 1',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'مالية عمومية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تاريخ الوقائع الاقتصادية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'اقتصاد نقدي',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'احصاء3',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'محاسبة التسيير',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'مدخل لادارة الاعمال',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'المنهجية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'اعلام آلي 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(label: 'S2', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'اقتصاد كلي 2',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاقتصاد الدولي',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاقتصاد الجزائري ',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تسيير المؤسسة',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'احصاء4',
                    coef: 3,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'أساسيات بحوث العمليات',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'ريادة الأعمال',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 100),
                      ProgramComponent('EXAM', 0),
                    ],
                  ),
                  ProgramModule(
                    name: 'أخلاقيات الأعمال',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                  ProgramModule(
                    name: 'لغة أجنبية 3',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ])
              ],
              )
            ],
          ),
          // //========================================================
          // //===============السنة الثالثةاقتصاد نقدي ومالي ===============
          ProgramTrack(
            name: S.of(context).monetaryFinancialEconomics,
            level: 'Licence 3',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'اقتصاد بنكي',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'النظريات والسياسات النقدية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تسيير المالي',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'محاسبة البنوك والتامينات',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'رياضيات مالية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                  ProgramModule(
                    name: S.of(context).businessLaw,
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'تحليل البيانات',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ],
                )
              ]),

              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'تقنيات واعمال البنوك',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'الاسواق المالية',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'الصيرفة الاسلامية',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'النظام المالي والبنكي الجزائري',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'اقتصاد قياسي',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'مشروع التخرج',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'جباية المؤسسة',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 100),
                        ProgramComponent('EXAM', 0),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),

          //========================================================
          // //===============السنة الرابعة اقتصاد نقدي ومالي===============
          ProgramTrack(
            name: S.of(context).monetaryFinancialEconomics,
            level: 'Master 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'اقتصاد بنكي معمق',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'تقنيات تسيير البورصة',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'مالية دولية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'محاسبة عمومية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'اقتصاد التامينات ',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاتصال والتحرير الاداري',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'تحليل السلاسل الزمنية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة 1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),
              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'التسيير البنكي',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'تسيير المحافظ المالية',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'اقتصاد كلي معمق',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'تقييم المشاريع',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'اقتصاد قياسي مالي',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'منهجية اعداد مدكر الماستر',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'تسويق الخدمات المالية والبنكية',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          // //========================================================
          // //===============السنة الخامسة  اقتصاد نقدي ومالي===============

          ProgramTrack(
            name: S.of(context).monetaryFinancialEconomics,
            level: 'Master 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'الهندسة المالية',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'التوجهات النقدية والمالية المعاصرة',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'التمويل الاسلامي',
                    coef: 3,
                    credits: 6,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'التدقيق البنكي',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'التكنلوجيا المالية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'التشريعات المالية والبنكية في الجزائر',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'برمجيات احصائية',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ],
                )
              ]),
            ],
          ),
          // //========================================================
          // //===============السنة الرابعة اقتصاد دولي===============
          ProgramTrack(
            name: S.of(context).internationalEconomics,
            level: 'Master 1',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: ' نظريات التجارة الدولية الحديثة',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاقتصاد الكلي المعمق',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الجغرافيا الاقتصادية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'بورصة البضائع',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'تحليل السلاسل الزمنية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الاتصال والتحرير الاداري',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'قانون الجمارك',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة 1',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ],
                )
              ]),
              // S2
              ProgramSemester(
                label: 'S2',
                unit: [
                  ProgramUnit(label: S.of(context).basicUnit, modules: [
                    ProgramModule(
                      name: 'المالية الدولية المعمقة',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'التسويق الدولي',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'الانتاج الدولي والشركات متعددة الجنسيات',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'تحليل المدخلات والمخرجات',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                    ProgramModule(
                      name: 'اقتصاد قياسي متقدم',
                      coef: 2,
                      credits: 5,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'منهجية اعداد مدكرة الماستر',
                      coef: 2,
                      credits: 4,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                    ProgramModule(
                      name: 'التفاوض والدبلوماسية الاقتصادية',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ]),
                  ProgramUnit(label: S.of(context).horizontalUnit, modules: [
                    ProgramModule(
                      name: 'لغة اجنبية متخصصة 2',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 0),
                        ProgramComponent('EXAM', 100),
                      ],
                    ),
                  ])
                ],
              )
            ],
          ),
          // //========================================================
          // //===============السنة الخامسة  اقتصاد دولي===============

          ProgramTrack(
            name: S.of(context).internationalEconomics,
            level: 'Master 2',
            semesters: [
              ProgramSemester(label: 'S1', unit: [
                ProgramUnit(label: S.of(context).basicUnit, modules: [
                  ProgramModule(
                    name: 'البلوكاتشين والتجارة الدولية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'الازمات الاقتصادية والمالية الدولية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'سلاسل القيمة العالمية',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'نمادج التوازن العام',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).methodologicalUnit, modules: [
                  ProgramModule(
                    name: 'تقنيات تمويل التجارة الخارجية',
                    coef: 2,
                    credits: 5,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                  ProgramModule(
                    name: 'استراتيجيات التصدير',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(label: S.of(context).exploratoryUnit, modules: [
                  ProgramModule(
                    name: 'العمليات الجمركية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ]),
                ProgramUnit(
                  label: S.of(context).horizontalUnit,
                  modules: [
                    ProgramModule(
                      name: 'برمجيات احصائية',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                  ],
                )
              ]),
            ],
          ),



        ],
      ),
    ]),
    ProgramFaculty(name: ' Coming soon', majors: [])

  ];
}
