// =======================
// 1. DEFINITIONS (MODELS)
// =======================
import 'package:flutter/material.dart';
import 'package:UniSpace/generated/l10n.dart';

class ProgramComponent {
  final String label;   // TD / TP / EXAM / CC...
  final double weight;  // نسبة مئوية 0..100
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

class ProgramSemester {
  final String label;         // S1 / S2
  final List<ProgramModule> modules;

  const ProgramSemester({
    required this.label,
    required this.modules,
  });
}

class ProgramTrack {
  final String name;          // L1 / L2 / L3 specialization
  final String level;
  final List<ProgramSemester> semesters;

  const ProgramTrack({
    required this.name,
    required this.level,
    required this.semesters,
  });
}


class ProgramMajor {
  final String name;          // التخصص

  final List<ProgramTrack> tracks;

  const ProgramMajor({
    required this.name,

    required this.tracks,
  });
}

class ProgramFaculty {
  final String name;          // الكلية
  final List<ProgramMajor> majors;

  const ProgramFaculty({
    required this.name,
    required this.majors,
  });
}

// =====================================================
// 2. DATA (DEMO) – CLEAN, VALID, EXPANDABLE
// =====================================================

List<ProgramFaculty> getDemoFaculties(BuildContext context) {
  return [

  ProgramFaculty(
    name: S.of(context).facultyEconomics,
    majors: [
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
              ProgramSemester(
                label: 'S1',
                modules: [
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
                    name: 'انجليزية 1',
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
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                ],
              ),

              // S2
              ProgramSemester(
                label: 'S2',
                modules: [
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
                    name: 'إنجليزية 2',
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
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
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
        name:S.of(context).managementSciencesDept ,
        tracks: [
          // ============================================
          // السنة 2 – قسم علوم التسيير
          // ============================================
          ProgramTrack(
            name: S.of(context).managementSciences,
            level: 'Licence 2',
            semesters: [
              // S1
              ProgramSemester(
                label: 'S1',
                modules: [
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
                  ProgramModule(
                    name: 'المنهجية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'اعلام آلي 2',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),

                    ],
                  ),
                ],
              ),

              //============================= S2
              ProgramSemester(
                label: 'S2',
                modules: [
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
                  ProgramModule(
                    name: 'ريادة الأعمال',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
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
                  ProgramModule(
                    name: 'لغة أجنبية 3',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ],
              ),
            ],
          ),


// //========================================================
// //===============السنة الثالثة ادارة اعمال===============


          ProgramTrack(
            name: S.of(context).businessAdministration,
            level: 'Licence 3',
            semesters: [
              // S1
              ProgramSemester(
                label: 'S1',
                modules: [
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
                  ProgramModule(
                    name: 'قانون الاعمال',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغة اجنبية متخصصة1',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),

              //============================= S2
              ProgramSemester(
                label: 'S2',
                modules: [
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
                  ProgramModule(
                    name: 'تحليل البيانات',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغة اجنبية متخصصة 2',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),
            ],
          ),

// //========================================================
// //===============السنة الثالثة ادارة مالية===============


          ProgramTrack(
            name: S.of(context).financialManagement,
            level: 'Licence 3',
            semesters: [
              // S1
              ProgramSemester(
                label: 'S1',
                modules: [
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
                  ProgramModule(
                    name: 'قانون الاعمال',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغة اجنبية متخصصة1',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),

              //============================= S2
              ProgramSemester(
                label: 'S2',
                modules: [
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
                  ProgramModule(
                    name: 'تحليل البيانات',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغة اجنبية متخصصة',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),
            ],
          ),

// //========================================================
// //===============السنة الثالثة ادارة موارد بشرية===============


          ProgramTrack(
            name: S.of(context).humanResourcesManagement,
            level: 'Licence 3',
            semesters: [
              // S1
              ProgramSemester(
                label: 'S1',
                modules: [
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
                  ProgramModule(
                    name: 'قانون العمل',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغة اجنبية متخصصة1',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),

              //============================= S2
              ProgramSemester(
                label: 'S2',
                modules: [
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
                  ProgramModule(
                    name: 'تحليل البيانات',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغة اجنبية متخصصة2',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),
            ],
          ),

          // //========================================================
// //===============السنة الرابعة ادارة اعمال===============


          ProgramTrack(
            name: S.of(context).businessAdministration,
            level: 'Master 1',
            semesters: [
              // S1
              ProgramSemester(
                label: 'S1',
                modules: [
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
                  ProgramModule(
                    name: 'تطبيقات التعلم العميق',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
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
              ),

              //============================= S2
              ProgramSemester(
                label: 'S2',
                modules: [
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
                    name: 'دكاء الاعمال وتنافسة المنظمات',
                    coef: 2,
                    credits: 4,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
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
                  ProgramModule(
                    name: 'التسويق الاستراتيجي',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغ.انج. للابحاث وكتابة المدكرات',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),
            ],
          ),

// //========================================================
// //===============السنة الخامسة ادارة اعمال===============


ProgramTrack(
name: S.of(context).businessAdministration,
level: 'Master 2',
semesters: [
// S1
ProgramSemester(
label: 'S1',
modules: [
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
ProgramModule(
name: 'قانون المنافسة وحماية المستهلك',
coef: 2,
credits: 2,
components: [
ProgramComponent('TD', 40),
ProgramComponent('EXAM', 60),
],
),
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
),
  ProgramSemester(
      label: 'S1',
      modules: [],)]),
// //========================================================
// //===============السنة الرابعة ادارة  مالية===============

          ProgramTrack(
            name: S.of(context).financialManagement,
            level: 'Master 1',
            semesters: [
              // S1
              ProgramSemester(
                label: 'S1',
                modules: [
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
                  ProgramModule(
                    name: 'تحليل السلاسل الزمنية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ك.ع.خ.اع. باللغة الانجليزية',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),

              //============================= S2
              ProgramSemester(
                label: 'S2',
                modules: [
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
                  ProgramModule(
                    name: 'قانون الصفقات العمومية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغ.انج.للابحاث وكتابة المدكرات',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),
            ],
          ),

// //========================================================
// //===============السنة الخامسة ادارة  مالية===============

          ProgramTrack(
name: S.of(context).financialManagement,
level: 'Master 2',
semesters: [
// S1
ProgramSemester(
label: 'S1',
modules: [
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

ProgramModule(
    name: 'التمويل الاسلامي',
    coef: 2,
    credits: 2,
    components: [
      ProgramComponent('TD', 40),
      ProgramComponent('EXAM', 60),
    ],
  ),
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
),ProgramSemester(
  label: 'S1',
  modules: [])]),

          // //========================================================
// //===============السنة الرابعة ادارة موارد بشرية===============

          ProgramTrack(
            name: S.of(context).humanResourcesManagement,
            level: 'Master 1',
            semesters: [
              // S1
              ProgramSemester(
                label: 'S1',
                modules: [
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
                  ProgramModule(
                    name: 'تطبيقات التعلم العميق',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'ك.ع.خ.اع. باللغة الانجليزية',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),

              //============================= S2
              ProgramSemester(
                label: 'S2',
                modules: [
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
                  ProgramModule(
                    name: 'التدقيق الاجتماعي',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغ.انج.للابحاث وكتابة المدكرات',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),
            ],
          ),

// //========================================================
// //===============السنة الخامسة ادارة موارد بشرية===============

          ProgramTrack(
              name: S.of(context).humanResourcesManagement,
              level: 'Master 2',
              semesters: [
// S1
                ProgramSemester(
                  label: 'S1',
                  modules: [
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

                    ProgramModule(
                      name: 'قانون الاساسي للوظيفة العمومية',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
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
                ),
                      ProgramSemester(
                      label: 'S1',
                      modules: [] )]),

          // //========================================================
// //===============السنة الرابعة التسيير المالي للمؤسسات===============

          ProgramTrack(
            name: S.of(context).corporateFinancialManagement,
            level: 'Master 1',
            semesters: [
              // S1
              ProgramSemester(
                label: 'S1',
                modules: [
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
                  ProgramModule(
                    name: 'قانون مكافحة الفساد',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

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
              ),

              //============================= S2
              ProgramSemester(
                label: 'S2',
                modules: [
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

                  ProgramModule(
                    name: 'قانون الاعمال',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
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
              ),
            ],
          ),

// //========================================================
// //===============السنة الخامسة التسيير المالي للمؤسسات===============

          ProgramTrack(
              name: S.of(context).corporateFinancialManagement,
              level: 'Master 2',
              semesters: [
// S1
                ProgramSemester(
                  label: 'S1',
                  modules: [
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

                    ProgramModule(
                      name: 'قانون الصفقات العمومية',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
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
                ),
                ProgramSemester(
  label: 'S1',
  modules: [])]),
        ],
      ),

      // ============================================
      //  قسم علوم تجارية
      // ============================================
      ProgramMajor(
        name: S.of(context).commercialSciencesDept,
        tracks: [
          // ============================================
          // السنة 2 – قسم علوم تجارية
          // ============================================
          ProgramTrack(
            name: S.of(context).commercialSciences,
            level: 'Licence 2',
            semesters: [
              // S1
              ProgramSemester(
                label: 'S1',
                modules: [
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
                  ProgramModule(
                    name: 'المنهجية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'اعلام آلي 2',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),

                    ],
                  ),
                ],
              ),

              //============================= S2
              ProgramSemester(
                label: 'S2',
                modules: [
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
                  ProgramModule(
                    name: 'ريادة الأعمال',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
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
                  ProgramModule(
                    name: 'لغة أجنبية3',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ],
              ),
            ],
          ),


// //========================================================
// //===============السنة الثالثة مالية وتجارة دولية===============


          ProgramTrack(
            name: S.of(context).financeInternationalTrade,
            level: 'Licence 3',
            semesters: [
              // S1
              ProgramSemester(
                label: 'S1',
                modules: [
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
                  ProgramModule(
                    name: 'قانون التجارة الدولية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغة اجنبية متخصصة1',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),

              //============================= S2
              ProgramSemester(
                label: 'S2',
                modules: [
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
                  ProgramModule(
                    name: 'برمجيات احصائية 1',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغة اجنبية متخصصة',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),
            ],
          ),

// //========================================================
// //===============السنة الثالثة تسويق===============


          ProgramTrack(
            name: S.of(context).marketing,
            level: 'Licence 3',
            semesters: [
              // S1
              ProgramSemester(
                label: 'S1',
                modules: [
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
                  ProgramModule(
                    name: 'قانون المنافسة وحماية المستهلك',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغة اجنبية متخصصة 1',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),

              //============================= S2
              ProgramSemester(
                label: 'S2',
                modules: [
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
                  ProgramModule(
                    name: 'برمجيات احصائية 1',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: ' لغة اجنبية متخصصة 2',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),
            ],
          ),


          // //========================================================
// //===============السنة الرابعة  تسويق الخدمات===============


          ProgramTrack(
            name: S.of(context).servicesMarketing,
            level: 'Master 1',
            semesters: [
              // S1
              ProgramSemester(
                label: 'S1',
                modules: [
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
                  ProgramModule(
                    name: 'تطبيقات في التسويق الرقمي',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغة اجنبية متخصصة 1',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),

              //============================= S2
              ProgramSemester(
                label: 'S2',
                modules: [
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
                  ProgramModule(
                    name: 'تسويق الخدمات العمومية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغة اجنبية متخصصة 2',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),
            ],
          ),

// //========================================================
// //===============السنة الخامسة  تسويق الخدمات===============


          ProgramTrack(
              name: S.of(context).servicesMarketing,
              level: 'Master 2',
              semesters: [
// S1
                ProgramSemester(
                  label: 'S1',
                  modules: [
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

                    ProgramModule(
                      name: 'قانون الاعمال',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ندوة في تسويق الخدمات',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),

                  ],
                ),ProgramSemester(
  label: 'S1',
  modules: [])]),
// //========================================================
// //===============السنة الرابعة تسويق فندقي وسياحي===============

          ProgramTrack(
            name: S.of(context).hotelTourismMarketing,
            level: 'Master 1',
            semesters: [
              // S1
              ProgramSemester(
                label: 'S1',
                modules: [
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
                  ProgramModule(
                    name: 'القانون السياحي والفندقي',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغة اجنبية متخصصة 1',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),

              //============================= S2
              ProgramSemester(
                label: 'S2',
                modules: [
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
                  ProgramModule(
                    name: 'الاساليب الكمية في التسويق 2',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغة اجنبية متخصصة 2',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),
            ],
          ),

// //========================================================
// //===============السنة الخامسة تسويق فندقي وسياحي===============

          ProgramTrack(
              name: S.of(context).hotelTourismMarketing,
              level: 'Master 2',
              semesters: [
// S1
                ProgramSemester(
                  label: 'S1',
                  modules: [
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

                    ProgramModule(
                      name: 'برمجيات التسويق السياحي الالكتروني',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
                    ProgramModule(
                      name: 'ندوة في التسويق الياحي والفندقي',
                      coef: 1,
                      credits: 1,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),

                  ],
                ),ProgramSemester(
  label: 'S1',
  modules: [])]),


        ],
      ),

      // ============================================
      //  قسم علوم مالية ومحاسبة
      // ============================================
      ProgramMajor(
        name: S.of(context).financialAccountingDept,
        tracks: [
          // ============================================
          // السنة 2 –  علوم مالية ومحاسبة
          // ============================================
          ProgramTrack(
            name:  S.of(context).financialAccounting,
            level: 'Licence 2',
            semesters: [
              // S1
              ProgramSemester(
                label: 'S1',
                modules: [
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
                  ProgramModule(
                    name: 'المنهجية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'اعلام آلي 2',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),

                    ],
                  ),
                ],
              ),

              //============================= S2
              ProgramSemester(
                label: 'S2',
                modules: [
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
                  ProgramModule(
                    name: 'ريادة الأعمال',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
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
                  ProgramModule(
                    name: 'لغة أجنبية 3',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 0),
                      ProgramComponent('EXAM', 100),
                    ],
                  ),
                ],
              ),
            ],
          ),


// //========================================================
// //===============السنة الثالثة مالية ===============


          ProgramTrack(
            name:  S.of(context).finance,
            level: 'Licence 3',
            semesters: [
              // S1
              ProgramSemester(
                label: 'S1',
                modules: [
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
                  ProgramModule(
                    name: 'قانون الاعمال',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغة اجنبية متخصصة1',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),

              //============================= S2
              ProgramSemester(
                label: 'S2',
                modules: [
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
                  ProgramModule(
                    name: 'تحليل البيانات',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغة اجنبية متخصصة 2',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),
            ],
          ),

// //========================================================
// //===============السنة الثالثة محاسبة===============


          ProgramTrack(
            name:  S.of(context).accounting,
            level: 'Licence 3',
            semesters: [
              // S1
              ProgramSemester(
                label: 'S1',
                modules: [
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
                  ProgramModule(
                    name: 'قانون الشركات',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغة اجنبية متخصصة 1',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),

              //============================= S2
              ProgramSemester(
                label: 'S2',
                modules: [
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
                  ProgramModule(
                    name: 'تحليل البيانات',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: ' لغة اجنبية متخصصة 2',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),
            ],
          ),


          // //========================================================
// //===============السنة الرابعة  محاسبة وجباية===============


          ProgramTrack(
            name:  S.of(context).accountingTaxation,
            level: 'Master 1',
            semesters: [
              // S1
              ProgramSemester(
                label: 'S1',
                modules: [
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
                  ProgramModule(
                    name: 'النمدجة الاحصائية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغة اجنبية متخصصة 1',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),

              //============================= S2
              ProgramSemester(
                label: 'S2',
                modules: [
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
                  ProgramModule(
                    name: 'برمجيات احصائية',
                    coef: 2,
                    credits: 2,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),
                  ProgramModule(
                    name: 'لغة اجنبية متخصصة 2',
                    coef: 1,
                    credits: 1,
                    components: [
                      ProgramComponent('TD', 40),
                      ProgramComponent('EXAM', 60),
                    ],
                  ),

                ],
              ),
            ],
          ),

// //========================================================
// //===============السنة الخامسة  محاسبة وجباية===============


          ProgramTrack(
              name:  S.of(context).accountingTaxation,
              level: 'Master 2',
              semesters: [
// S1
                ProgramSemester(
                  label: 'S1',
                  modules: [
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

                    ProgramModule(
                      name: 'القانون الجزائي للاعمال',
                      coef: 2,
                      credits: 2,
                      components: [
                        ProgramComponent('TD', 40),
                        ProgramComponent('EXAM', 60),
                      ],
                    ),
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
                ),ProgramSemester(
  label: 'S1',
  modules: [])]),
// // //========================================================
// // //===============السنة الرابعة مالية المؤسسة===============
//
           ProgramTrack(
             name:  S.of(context).corporateFinance,
             level: 'Master 1',
             semesters: [
//               // S1
//               ProgramSemester(
//                 label: 'S1',
//                 modules: [
//                   ProgramModule(
//                     name: ' اد. خدمات السياحية والفندقية',
//                     coef: 2,
//                     credits: 5,
//                     components: [
//                       ProgramComponent('TD', 40),
//                       ProgramComponent('EXAM', 60),
//                     ],
//                   ),
//                   ProgramModule(
//                     name: 'التسويق السياحي',
//                     coef: 2,
//                     credits: 5,
//                     components: [
//                       ProgramComponent('TD', 40),
//                       ProgramComponent('EXAM', 60),
//                     ],
//                   ),
//                   ProgramModule(
//                     name: 'التسويق الفندقي',
//                     coef: 2,
//                     credits: 4,
//                     components: [
//                       ProgramComponent('TD', 40),
//                       ProgramComponent('EXAM', 60),
//                     ],
//                   ),
//                   ProgramModule(
//                     name: 'سلوك المستهلك السياحي',
//                     coef: 2,
//                     credits: 4,
//                     components: [
//                       ProgramComponent('TD', 40),
//                       ProgramComponent('EXAM', 60),
//                     ],
//                   ),
//                   ProgramModule(
//                     name: 'الاساليب الكمية في التسويق 1',
//                     coef: 2,
//                     credits: 5,
//                     components: [
//                       ProgramComponent('TD', 40),
//                       ProgramComponent('EXAM', 60),
//                     ],
//                   ),
//                   ProgramModule(
//                     name: 'الاتصال والتحرير الاداري',
//                     coef: 2,
//                     credits: 4,
//                     components: [
//                       ProgramComponent('TD', 40),
//                       ProgramComponent('EXAM', 60),
//                     ],
//                   ),
//                   ProgramModule(
//                     name: 'القانون السياحي والفندقي',
//                     coef: 2,
//                     credits: 2,
//                     components: [
//                       ProgramComponent('TD', 40),
//                       ProgramComponent('EXAM', 60),
//                     ],
//                   ),
//                   ProgramModule(
//                     name: 'لغة اجنبية متخصصة 1',
//                     coef: 1,
//                     credits: 1,
//                     components: [
//                       ProgramComponent('TD', 40),
//                       ProgramComponent('EXAM', 60),
//                     ],
//                   ),
//
//                 ],
//               ),
//
//               //============================= S2
//               ProgramSemester(
//                 label: 'S2',
//                 modules: [
//                   ProgramModule(
//                     name: 'اد. جودة الخدمات السياحية',
//                     coef: 2,
//                     credits: 5,
//                     components: [
//                       ProgramComponent('TD', 40),
//                       ProgramComponent('EXAM', 60),
//                     ],
//                   ),
//                   ProgramModule(
//                     name: 'الاتصال التسويقي السياحي',
//                     coef: 2,
//                     credits: 5,
//                     components: [
//                       ProgramComponent('TD', 40),
//                       ProgramComponent('EXAM', 60),
//                     ],
//                   ),
//                   ProgramModule(
//                     name: 'ادارة العلامة التجارية',
//                     coef: 2,
//                     credits: 4,
//                     components: [
//                       ProgramComponent('TD', 40),
//                       ProgramComponent('EXAM', 60),
//                     ],
//                   ),
//                   ProgramModule(
//                     name: 'ادارة علاقات العملاء',
//                     coef: 2,
//                     credits: 4,
//                     components: [
//                       ProgramComponent('TD', 40),
//                       ProgramComponent('EXAM', 60),
//                     ],
//                   ),
//                   ProgramModule(
//                     name: 'الجغرافيا السياحية',
//                     coef: 2,
//                     credits: 5,
//                     components: [
//                       ProgramComponent('TD', 40),
//                       ProgramComponent('EXAM', 60),
//                     ],
//                   ),
//                   ProgramModule(
//                     name: 'م.اعداد مدكرة الماستر',
//                     coef: 2,
//                     credits: 4,
//                     components: [
//                       ProgramComponent('TD', 40),
//                       ProgramComponent('EXAM', 60),
//                     ],
//                   ),
//                   ProgramModule(
//                     name: 'الاساليب الكمية في التسويق 2',
//                     coef: 2,
//                     credits: 2,
//                     components: [
//                       ProgramComponent('TD', 40),
//                       ProgramComponent('EXAM', 60),
//                     ],
//                   ),
//                   ProgramModule(
//                     name: 'لغة اجنبية متخصصة 2',
//                     coef: 1,
//                     credits: 1,
//                     components: [
//                       ProgramComponent('TD', 40),
//                       ProgramComponent('EXAM', 60),
//                     ],
//                   ),
//
//                 ],
//               ),
             ],
           ),

// //========================================================
// //===============السنة الخامسة مالية مؤسسة===============

//           ProgramTrack(
//               name: 'تسويق فندقي وسياحي',
//               level: 'Master 2',
//               semesters: [
// // S1
//                 ProgramSemester(
//                   label: 'S1',
//                   modules: [
//                     ProgramModule(
//                       name: 'التحليل الاستراتيجي والتنافسي',
//                       coef: 3,
//                       credits: 6,
//                       components: [
//                         ProgramComponent('TD', 40),
//                         ProgramComponent('EXAM', 60),
//                       ],
//                     ),
//                     ProgramModule(
//                       name: 'اد. الاحداث والوجهات السياحية',
//                       coef: 3,
//                       credits: 6,
//                       components: [
//                         ProgramComponent('TD', 40),
//                         ProgramComponent('EXAM', 60),
//                       ],
//                     ),
//                     ProgramModule(
//                       name: 'اد. الموارد البشرية السياحية',
//                       coef: 3,
//                       credits: 6,
//                       components: [
//                         ProgramComponent('TD', 40),
//                         ProgramComponent('EXAM', 60),
//                       ],
//                     ),
//                     ProgramModule(
//                       name: 'برمجيات احصائية 2',
//                       coef: 2,
//                       credits: 5,
//                       components: [
//                         ProgramComponent('TD', 40),
//                         ProgramComponent('EXAM', 60),
//                       ],
//                     ),
//                     ProgramModule(
//                       name: 'اد. شركات والوكالات السياحية',
//                       coef: 2,
//                       credits: 4,
//                       components: [
//                         ProgramComponent('TD', 40),
//                         ProgramComponent('EXAM', 60),
//                       ],
//                     ),
//
//                     ProgramModule(
//                       name: 'برمجيات التسويق السياحي الالكتروني',
//                       coef: 2,
//                       credits: 2,
//                       components: [
//                         ProgramComponent('TD', 40),
//                         ProgramComponent('EXAM', 60),
//                       ],
//                     ),
//                     ProgramModule(
//                       name: 'ندوة في التسويق الياحي والفندقي',
//                       coef: 1,
//                       credits: 1,
//                       components: [
//                         ProgramComponent('TD', 40),
//                         ProgramComponent('EXAM', 60),
//                       ],
//                     ),
//
//                   ],
//                 ),]),


        ],
      ),
// ============================================
//  قسم علوم اقتصادية
// ============================================
ProgramMajor(
name:S.of(context).economicsDept ,
tracks: [
// ============================================
// السنة 2 –  علوم اقتصادية
// ============================================
ProgramTrack(
name:S.of(context).economics,
level: 'Licence 2',
semesters: [
// S1
ProgramSemester(
label: 'S1',
modules: [
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
ProgramModule(
name: 'المنهجية',
coef: 2,
credits: 2,
components: [
ProgramComponent('TD', 40),
ProgramComponent('EXAM', 60),
],
),
ProgramModule(
name: 'اعلام آلي 2',
coef: 1,
credits: 1,
components: [
ProgramComponent('TD', 40),
ProgramComponent('EXAM', 60),

],
),
],
),

//============================= S2
ProgramSemester(
label: 'S2',
modules: [
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
ProgramModule(
name: 'ريادة الأعمال',
coef: 1,
credits: 1,
components: [
ProgramComponent('TD', 0),
ProgramComponent('EXAM', 100),
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
ProgramModule(
name: 'لغة أجنبية 3',
coef: 1,
credits: 1,
components: [
ProgramComponent('TD', 0),
ProgramComponent('EXAM', 100),
],
),
],
),
],
),


// //========================================================
// //===============السنة الثالثة اقتصاد نقدي ومالي ===============


ProgramTrack(
name:S.of(context).monetaryFinancialEconomics,
level: 'Licence 3',
semesters: [
// S1
ProgramSemester(
label: 'S1',
modules: [
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
name: 'قانون الاعمال',
coef: 1,
credits: 1,
components: [
ProgramComponent('TD', 0),
ProgramComponent('EXAM', 100),
],
),
  ProgramModule(
    name: 'تحليل البيانات',
    coef: 2,
    credits: 2,
    components: [
      ProgramComponent('TD', 40),
      ProgramComponent('EXAM', 60),
    ],
  ),
ProgramModule(
name: 'لغة اجنبية متخصصة1',
coef: 1,
credits: 1,
components: [
ProgramComponent('TD', 40),
ProgramComponent('EXAM', 60),
],
),

],
),

//============================= S2
ProgramSemester(
label: 'S2',
modules: [
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
ProgramModule(
name: 'جباية المؤسسة',
coef: 2,
credits: 2,
components: [
ProgramComponent('TD', 40),
ProgramComponent('EXAM', 60),
],
),
ProgramModule(
name: 'لغة اجنبية متخصصة 2',
coef: 1,
credits: 1,
components: [
ProgramComponent('TD', 40),
ProgramComponent('EXAM', 60),
],
),

],
),
],
),

  // //========================================================
// //===============السنة الرابعة  اقتصاد نقدي ومالي===============


  ProgramTrack(
    name: S.of(context).monetaryFinancialEconomics,
    level: 'Master 1',
    semesters: [
      // S1
      ProgramSemester(
        label: 'S1',
        modules: [
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
          ProgramModule(
            name: 'تحليل السلاسل الزمنية',
            coef: 2,
            credits: 2,
            components: [
              ProgramComponent('TD', 40),
              ProgramComponent('EXAM', 60),
            ],
          ),
          ProgramModule(
            name: 'لغة اجنبية متخصصة 1',
            coef: 1,
            credits: 1,
            components: [
              ProgramComponent('TD', 40),
              ProgramComponent('EXAM', 60),
            ],
          ),

        ],
      ),

      //============================= S2
      ProgramSemester(
        label: 'S2',
        modules: [
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
          ProgramModule(
            name: 'تسويق الخدمات المالية والبنكية',
            coef: 2,
            credits: 2,
            components: [
              ProgramComponent('TD', 40),
              ProgramComponent('EXAM', 60),
            ],
          ),
          ProgramModule(
            name: 'لغة اجنبية متخصصة 2',
            coef: 1,
            credits: 1,
            components: [
              ProgramComponent('TD', 40),
              ProgramComponent('EXAM', 60),
            ],
          ),

        ],
      ),
    ],
  ),

// //========================================================
// //===============السنة الخامسة  اقتصاد نقدي ومالي===============


  ProgramTrack(
      name: S.of(context).monetaryFinancialEconomics,
      level: 'Master 2',
      semesters: [
// S1
        ProgramSemester(
          label: 'S1',
          modules: [
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

            ProgramModule(
              name: 'التشريعات المالية والبنكية في الجزائر',
              coef: 2,
              credits: 2,
              components: [
                ProgramComponent('TD', 40),
                ProgramComponent('EXAM', 60),
              ],
            ),
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
        ),
        ]),
// //========================================================
// //===============السنة الرابعة اقتصاد دولي===============

  ProgramTrack(
    name: S.of(context).internationalEconomics,
    level: 'Master 1',
    semesters: [
      // S1
      ProgramSemester(
        label: 'S1',
        modules: [
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
          ProgramModule(
            name: 'قانون الجمارك',
            coef: 2,
            credits: 2,
            components: [
              ProgramComponent('TD', 40),
              ProgramComponent('EXAM', 60),
            ],
          ),
          ProgramModule(
            name: 'لغة اجنبية متخصصة 1',
            coef: 1,
            credits: 1,
            components: [
              ProgramComponent('TD', 40),
              ProgramComponent('EXAM', 60),
            ],
          ),

        ],
      ),

      //============================= S2
      ProgramSemester(
        label: 'S2',
        modules: [
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
          ProgramModule(
            name: 'التفاوض والدبلوماسية الاقتصادية',
            coef: 2,
            credits: 2,
            components: [
              ProgramComponent('TD', 40),
              ProgramComponent('EXAM', 60),
            ],
          ),
          ProgramModule(
            name: 'لغة اجنبية متخصصة 2',
            coef: 1,
            credits: 1,
            components: [
              ProgramComponent('TD', 40),
              ProgramComponent('EXAM', 60),
            ],
          ),

        ],
      ),
    ],
  ),

// //========================================================
// //===============السنة الخامسة  اقتصاد دولي===============

  ProgramTrack(
      name: S.of(context).internationalEconomics,
      level: 'Master 2',
      semesters: [
// S1
        ProgramSemester(
          label: 'S1',
          modules: [
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
            ProgramModule(
              name: 'العمليات الجمركية',
              coef: 2,
              credits: 2,
              components: [
                ProgramComponent('TD', 40),
                ProgramComponent('EXAM', 60),
              ],
            ),
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
        ),]),


])

    ],
  ),
  ProgramFaculty(
name: ' Coming soon',
majors: [])
];}