import 'package:flutter/widgets.dart';

/// Display-only catalog lookup. Never use the result as a persisted course key.
String academicText(BuildContext context, String canonical) =>
    AcademicStrings.text(
        Localizations.localeOf(context).languageCode, canonical);

abstract final class AcademicStrings {
  static final _numbered = RegExp(r'^(.*?)(\d+)\s*$');

  static (String, String) _parts(String canonical) {
    final trimmed = canonical.trim();
    final numbered = _numbered.firstMatch(trimmed);
    return numbered == null
        ? (trimmed, '')
        : (numbered[1]!.trim(), ' ${numbered[2]}');
  }

  static bool hasTranslation(String canonical) =>
      _names.containsKey(_parts(canonical).$1);

  static String text(String languageCode, String canonical) {
    final (base, suffix) = _parts(canonical);
    if (languageCode == 'ar') {
      final arabic = _arabicLabels[base];
      return arabic == null ? canonical : '$arabic$suffix';
    }
    final translation = _names[base];
    if (translation == null) return canonical;
    return '${translation[languageCode == 'fr' ? 1 : 0]}$suffix';
  }

  static const _arabicLabels = <String, String>{
    'Coming soon': 'قريبًا',
    'Licence': 'ليسانس',
    'S': 'السداسي',
    'EXAM': 'الامتحان',
    'TD': 'أعمال موجهة',
    'TP': 'أعمال تطبيقية',
    'CC': 'تقييم مستمر',
  };

  // Exact known catalog spellings are intentional: .name stays unchanged.
  // The opaque ك.ع.خ.اع. abbreviation is retained until its author supplies an expansion.
  static const _names = <String, List<String>>{
    'EXAM': ['Exam', 'Examen'],
    'TD': ['Tutorials', 'TD'],
    'TP': ['Practical work', 'TP'],
    'CC': ['Continuous assessment', 'Contrôle continu'],
    "Coming soon": ["Coming soon", "Bientôt disponible"],
    "Licence": ["Bachelor year", "Licence"],
    "S": ["Semester", "Semestre"],
    "أخلاقيات الأعمال": ["Business ethics", "Éthique des affaires"],
    "أساسيات بحوث العمليات": [
      "Fundamentals of operations research",
      "Fondements de la recherche opérationnelle"
    ],
    "إعلام آلي": ["Computing", "Informatique"],
    "إنجليزية": ["English", "Anglais"],
    "ابتكار وتطوير الخدمات": [
      "Service innovation and development",
      "Innovation et développement des services"
    ],
    "ابرام وتحرير عقود الطاقة": [
      "Energy contract drafting and conclusion",
      "Rédaction et conclusion des contrats énergétiques"
    ],
    "احصاء": ["Statistics", "Statistiques"],
    "احكام الفرائض": [
      "Rules of inheritance shares",
      "Règles des parts successorales"
    ],
    "اخلاقيات البحث العلمي": [
      "Research ethics",
      "Éthique de la recherche scientifique"
    ],
    "اخلاقيات المهن القضائية": [
      "Judicial professional ethics",
      "Déontologie des professions judiciaires"
    ],
    "اد. الاحداث والوجهات السياحية": [
      "Tourism event and destination management",
      "Gestion des événements et destinations touristiques"
    ],
    "اد. الموارد البشرية السياحية": [
      "Tourism human resources management",
      "Gestion des ressources humaines touristiques"
    ],
    "اد. جودة الخدمات السياحية": [
      "Tourism service quality management",
      "Gestion de la qualité des services touristiques"
    ],
    "اد. خدمات السياحية والفندقية": [
      "Tourism and hotel service management",
      "Gestion des services touristiques et hôteliers"
    ],
    "اد. شركات والوكالات السياحية": [
      "Tourism company and agency management",
      "Gestion des entreprises et agences touristiques"
    ],
    "اداب واحلاقيات المهنة": [
      "Professional ethics and conduct",
      "Éthique et déontologie professionnelles"
    ],
    "اداب واخلاقيات المهنة": [
      "Professional ethics and conduct",
      "Éthique et déontologie professionnelles"
    ],
    "ادارة استراتيجية": ["Strategic management", "Management stratégique"],
    "ادارة استراتيجية للموارد البشرية": [
      "Strategic human resources management",
      "Gestion stratégique des ressources humaines"
    ],
    "ادارة الابداع والابتكار": [
      "Creativity and innovation management",
      "Gestion de la créativité et de l’innovation"
    ],
    "ادارة الاجور والحوافز": [
      "Pay and incentive management",
      "Gestion des rémunérations et des incitations"
    ],
    "ادارة الاحداث والوجهات السياحية": [
      "Tourism event and destination management",
      "Gestion des événements et destinations touristiques"
    ],
    "ادارة الاداء والتميز": [
      "Performance and excellence management",
      "Gestion de la performance et de l’excellence"
    ],
    "ادارة الاعمال الدولية": [
      "International business management",
      "Gestion des affaires internationales"
    ],
    "ادارة الانتاج والعمليات": [
      "Production and operations management",
      "Gestion de la production et des opérations"
    ],
    "ادارة التدفقات المالية": [
      "Financial flow management",
      "Gestion des flux financiers"
    ],
    "ادارة التعاقد والتفاوض": [
      "Contracting and negotiation management",
      "Gestion des contrats et de la négociation"
    ],
    "ادارة التغيير": ["Change management", "Gestion du changement"],
    "ادارة الجودة الشاملة": [
      "Total quality management",
      "Management de la qualité totale"
    ],
    "ادارة الجودة والتمييز": [
      "Quality and excellence management",
      "Gestion de la qualité et de l’excellence"
    ],
    "ادارة الخدمات": ["Service management", "Gestion des services"],
    "ادارة الخدمات السياحية والفندقية": [
      "Tourism and hotel service management",
      "Gestion des services touristiques et hôteliers"
    ],
    "ادارة العلاقات العامة": [
      "Public relations management",
      "Gestion des relations publiques"
    ],
    "ادارة العلامة التجارية": ["Brand management", "Gestion de la marque"],
    "ادارة الكترونية للموارد البشرية": [
      "Digital human resources management",
      "Gestion électronique des ressources humaines"
    ],
    "ادارة الكفاءات": ["Skills management", "Gestion des compétences"],
    "ادارة المؤسسات المالية والتمويل": [
      "Financial institution and financing management",
      "Gestion des institutions financières et du financement"
    ],
    "ادارة المبيعات والقوى البيعية": [
      "Sales and sales force management",
      "Gestion des ventes et de la force de vente"
    ],
    "ادارة المحفظة المالية": [
      "Portfolio management",
      "Gestion de portefeuille financier"
    ],
    "ادارة المخاطر الاجتاعية": [
      "Social risk management",
      "Gestion des risques sociaux"
    ],
    "ادارة المخاطر المالية": [
      "Financial risk management",
      "Gestion des risques financiers"
    ],
    "ادارة المرافق العمومية": [
      "Public service management",
      "Gestion des services publics"
    ],
    "ادارة المسارات المهنية": ["Career management", "Gestion des carrières"],
    "ادارة المشاريع": ["Project management", "Gestion de projets"],
    "ادارة المعرفة": ["Knowledge management", "Gestion des connaissances"],
    "ادارة الموارد البشرية": [
      "Human resources management",
      "Gestion des ressources humaines"
    ],
    "ادارة الموارد البشرية السياحية": [
      "Tourism human resources management",
      "Gestion des ressources humaines touristiques"
    ],
    "ادارة تكنلوجيا المعلومات": [
      "Information technology management",
      "Gestion des technologies de l’information"
    ],
    "ادارة جودة الخدمات": [
      "Service quality management",
      "Gestion de la qualité des services"
    ],
    "ادارة جودة الخدمات السياحية": [
      "Tourism service quality management",
      "Gestion de la qualité des services touristiques"
    ],
    "ادارة سلسلة الامداد": [
      "Supply chain management",
      "Gestion de la chaîne logistique"
    ],
    "ادارة شركات والوكالات السياحية": [
      "Tourism company and agency management",
      "Gestion des entreprises et agences touristiques"
    ],
    "ادارة علاقات العملاء": [
      "Customer relationship management",
      "Gestion de la relation client"
    ],
    "ادارة مالية": ["Financial management", "Gestion financière"],
    "ادارة مشاريع الكترونية": [
      "Digital project management",
      "Gestion des projets numériques"
    ],
    "ادارة مصادر التمويل": [
      "Management of financing sources",
      "Gestion des sources de financement"
    ],
    "ادراة تكنولوجيا المعلومات": [
      "Information technology management",
      "Gestion des technologies de l’information"
    ],
    "اساسيات التسويق": ["Marketing fundamentals", "Fondements du marketing"],
    "استراتيجيات التصدير": ["Export strategies", "Stratégies d’exportation"],
    "استراتيجيات الشركات متعددة الجنسيات": [
      "Multinational company strategies",
      "Stratégies des entreprises multinationales"
    ],
    "اسس ادارة الموارد البشرية": [
      "Human resources management fundamentals",
      "Fondements de la gestion des ressources humaines"
    ],
    "اسواق مالية": ["Financial markets", "Marchés financiers"],
    "اصلاح الادارة ومحاربة الفساد": [
      "Administrative reform and anti-corruption",
      "Réforme administrative et lutte contre la corruption"
    ],
    "اعلام آلي": ["Computing", "Informatique"],
    "اعلام الي": ["Computing", "Informatique"],
    "اقتصاد التامينات": ["Insurance economics", "Économie des assurances"],
    "اقتصاد المؤسسة": ["Business economics", "Économie de l’entreprise"],
    "اقتصاد بنكي": ["Banking economics", "Économie bancaire"],
    "اقتصاد بنكي معمق": [
      "Advanced banking economics",
      "Économie bancaire approfondie"
    ],
    "اقتصاد جزئي": ["Microeconomics", "Microéconomie"],
    "اقتصاد سياسي": ["Political economy", "Économie politique"],
    "اقتصاد قياسي": ["Econometrics", "Économétrie"],
    "اقتصاد قياسي مالي": ["Financial econometrics", "Économétrie financière"],
    "اقتصاد قياسي متقدم": ["Advanced econometrics", "Économétrie avancée"],
    "اقتصاد كلي": ["Macroeconomics", "Macroéconomie"],
    "اقتصاد كلي معمق": ["Advanced macroeconomics", "Macroéconomie approfondie"],
    "اقتصاد نقدي": ["Monetary economics", "Économie monétaire"],
    "اقتصاديات التنمية": ["Development economics", "Économie du développement"],
    "الاتجاهات الحديثة في التسيير": [
      "Modern management trends",
      "Tendances modernes de la gestion"
    ],
    "الاتصال التسويقي السياحي": [
      "Tourism marketing communication",
      "Communication marketing touristique"
    ],
    "الاتصال التنظيمي": [
      "Organizational communication",
      "Communication organisationnelle"
    ],
    "الاتصال والتحرير الاداري": [
      "Administrative communication and writing",
      "Communication et rédaction administratives"
    ],
    "الاتصالات التسويقية المتكاملة": [
      "Integrated marketing communications",
      "Communication marketing intégrée"
    ],
    "الاثبات الجنائي": ["Criminal evidence", "Preuve pénale"],
    "الاثبات الجنائي الجبائي": [
      "Evidence in tax crimes",
      "Preuve pénale fiscale"
    ],
    "الاجراءات القضائية الادارية": [
      "Administrative judicial procedures",
      "Procédures juridictionnelles administratives"
    ],
    "الاحزاب السياسية والقانون الانتخابي": [
      "Political parties and electoral law",
      "Partis politiques et droit électoral"
    ],
    "الاخلاق والسلوك المهني": [
      "Ethics and professional conduct",
      "Éthique et comportement professionnel"
    ],
    "الادارة الاستراتيجية": ["Strategic management", "Management stratégique"],
    "الادارة الالكترونية": [
      "Electronic administration",
      "Administration électronique"
    ],
    "الادارة العامة": ["Public administration", "Administration publique"],
    "الادارة العامة المقارنة": [
      "Comparative public administration",
      "Administration publique comparée"
    ],
    "الادارة المالية": ["Financial management", "Gestion financière"],
    "الادارة المالية الدولية": [
      "International financial management",
      "Gestion financière internationale"
    ],
    "الادارة الماليةالمتقدمة": [
      "Advanced financial management",
      "Gestion financière avancée"
    ],
    "الادب نظريات وممارسات": [
      "Literature: theories and practices",
      "Littérature : théories et pratiques"
    ],
    "الازمات الاقتصادية والمالية الدولية": [
      "International economic and financial crises",
      "Crises économiques et financières internationales"
    ],
    "الاساليب الكمية في الادارة": [
      "Quantitative management methods",
      "Méthodes quantitatives de gestion"
    ],
    "الاساليب الكمية في التسويق": [
      "Quantitative marketing methods",
      "Méthodes quantitatives en marketing"
    ],
    "الاساليب الكمية في التويق": [
      "Quantitative marketing methods",
      "Méthodes quantitatives en marketing"
    ],
    "الاساليب الكميية في التسويق": [
      "Quantitative marketing methods",
      "Méthodes quantitatives en marketing"
    ],
    "الاساليب لكمية في الادارة": [
      "Quantitative management methods",
      "Méthodes quantitatives de gestion"
    ],
    "الاسواق المالية": ["Financial markets", "Marchés financiers"],
    "الاصلاح السياسي والاداري في الجزائر/ السياسات البيئية والتعمير": [
      "Political and administrative reform in Algeria / Environmental and urban planning policies",
      "Réforme politique et administrative en Algérie / Politiques environnementales et d’urbanisme"
    ],
    "الاعلام الالي": ["Computing", "Informatique"],
    "الاقتصاد الجزائري": ["Algerian economy", "Économie algérienne"],
    "الاقتصاد الدولي": ["International economics", "Économie internationale"],
    "الاقتصاد الكلي المعمق": [
      "Advanced macroeconomics",
      "Macroéconomie approfondie"
    ],
    "الانتاج الدولي والشركات متعددة الجنسيات": [
      "International production and multinational companies",
      "Production internationale et entreprises multinationales"
    ],
    "الانظمة العقابية البديلة": [
      "Alternative penal systems",
      "Systèmes de sanctions alternatives"
    ],
    "الاوراق التجارية والافلاس": [
      "Commercial paper and bankruptcy",
      "Effets de commerce et faillite"
    ],
    "البرمجة": ["Programming", "Programmation"],
    "البرمجيات الحرة والمصادر المفتوحة": [
      "Free and open-source software",
      "Logiciels libres et open source"
    ],
    "البلوكاتشين والتجارة الدولية": [
      "Blockchain and international trade",
      "Blockchain et commerce international"
    ],
    "التامين البحري": ["Marine insurance", "Assurance maritime"],
    "التبرعات": ["Gifts and donations", "Libéralités"],
    "التجارة الالكترونية": ["E-commerce", "Commerce électronique"],
    "التحرير الاداري و القضائي": [
      "Administrative and judicial writing",
      "Rédaction administrative et judiciaire"
    ],
    "التحكيم التجاري الدولي": [
      "International commercial arbitration",
      "Arbitrage commercial international"
    ],
    "التحليل الاستراتيجي والتنافسي": [
      "Strategic and competitive analysis",
      "Analyse stratégique et concurrentielle"
    ],
    "التخطيط المالي": ["Financial planning", "Planification financière"],
    "التخطيط والرقابة المالية": [
      "Financial planning and control",
      "Planification et contrôle financiers"
    ],
    "التدقيق الاجتماعي": ["Social auditing", "Audit social"],
    "التدقيق البنكي": ["Bank auditing", "Audit bancaire"],
    "التدقيق المالي": ["Financial auditing", "Audit financier"],
    "الترجمة": ["Translation", "Traduction"],
    "التركات والمواريث": [
      "Estates and inheritance",
      "Successions et héritages"
    ],
    "التسويق": ["Marketing", "Marketing"],
    "التسويق الاستراتيجي": ["Strategic marketing", "Marketing stratégique"],
    "التسويق الدولي": ["International marketing", "Marketing international"],
    "التسويق الرقمي": ["Digital marketing", "Marketing numérique"],
    "التسويق السياحي": ["Tourism marketing", "Marketing touristique"],
    "التسويق السياحي والفندقي": [
      "Tourism and hotel marketing",
      "Marketing touristique et hôtelier"
    ],
    "التسويق العملياتي": ["Operational marketing", "Marketing opérationnel"],
    "التسويق الفندقي": ["Hotel marketing", "Marketing hôtelier"],
    "التسيير البنكي": ["Bank management", "Gestion bancaire"],
    "التسيير الجبائي للمؤسسة": [
      "Business tax management",
      "Gestion fiscale de l’entreprise"
    ],
    "التسيير القانوني للشركات": [
      "Legal management of companies",
      "Gestion juridique des sociétés"
    ],
    "التسيير المالي": ["Financial management", "Gestion financière"],
    "التسيير المالي المعمق": [
      "Advanced financial management",
      "Gestion financière approfondie"
    ],
    "التشخيص المالي للمؤسسات": [
      "Business financial diagnosis",
      "Diagnostic financier des entreprises"
    ],
    "التشريع في الجزائر": ["Legislation in Algeria", "Législation en Algérie"],
    "التشريعات المالية والبنكية في الجزائر": [
      "Financial and banking legislation in Algeria",
      "Législation financière et bancaire en Algérie"
    ],
    "التصادم البحري": ["Maritime collisions", "Abordage maritime"],
    "التعاون الدولي في مجال الطاقة": [
      "International energy cooperation",
      "Coopération internationale dans le domaine de l’énergie"
    ],
    "التعاون الدولي في مجال الهجرة واللجوء": [
      "International cooperation on migration and asylum",
      "Coopération internationale en matière de migration et d’asile"
    ],
    "التعاون الدولي والامن في المتوسط": [
      "International cooperation and Mediterranean security",
      "Coopération internationale et sécurité en Méditerranée"
    ],
    "التعاون الدولي والتنمية المستدامة": [
      "International cooperation and sustainable development",
      "Coopération internationale et développement durable"
    ],
    "التعاون الدولي وبناء السلام": [
      "International cooperation and peacebuilding",
      "Coopération internationale et consolidation de la paix"
    ],
    "التعاون الدولي وحقوق الانسان": [
      "International cooperation and human rights",
      "Coopération internationale et droits humains"
    ],
    "التفاوض التجاري": ["Commercial negotiation", "Négociation commerciale"],
    "التفاوض والدبلوماسية الاقتصادية": [
      "Negotiation and economic diplomacy",
      "Négociation et diplomatie économique"
    ],
    "التكتلات والمنظمات الدولية": [
      "International blocs and organizations",
      "Groupements et organisations internationaux"
    ],
    "التكنلوجيا المالية": ["Financial technology", "Technologie financière"],
    "التمويل الاسلامي": ["Islamic finance", "Finance islamique"],
    "التنافس الدولي في افريقيا/التنافس الدولي في الشرق الاوسط": [
      "International competition in Africa / International competition in the Middle East",
      "Concurrence internationale en Afrique / Concurrence internationale au Moyen-Orient"
    ],
    "التنظيم القضائي": ["Judicial organization", "Organisation judiciaire"],
    "التهرب والغش الجبائي": [
      "Tax evasion and fraud",
      "Évasion et fraude fiscales"
    ],
    "التوجهات النقدية والمالية المعاصرة": [
      "Contemporary monetary and financial trends",
      "Tendances monétaires et financières contemporaines"
    ],
    "الجباية الايكولوجية": ["Environmental taxation", "Fiscalité écologique"],
    "الجباية الدولية": ["International taxation", "Fiscalité internationale"],
    "الجباية المعمقة": ["Advanced taxation", "Fiscalité approfondie"],
    "الجباية في المجال الطاقوي والمنجمي": [
      "Energy and mining taxation",
      "Fiscalité énergétique et minière"
    ],
    "الجريمة الجمركية": ["Customs crime", "Infractions douanières"],
    "الجغرافيا الاقتصادية": ["Economic geography", "Géographie économique"],
    "الجغرافيا السياحية": ["Tourism geography", "Géographie touristique"],
    "الجغرافيا السياسية/الاحزاب السياسية والنظم الانتخابية": [
      "Political geography / Political parties and electoral systems",
      "Géographie politique / Partis politiques et systèmes électoraux"
    ],
    "الحريات العامة": ["Public freedoms", "Libertés publiques"],
    "الحكم الراشد والحوكمة المحلية": [
      "Good governance and local governance",
      "Bonne gouvernance et gouvernance locale"
    ],
    "الحماية الجزائية للاسرة": [
      "Criminal-law protection of the family",
      "Protection pénale de la famille"
    ],
    "الحماية المؤسساتية للاسرة و الطفولة": [
      "Institutional protection of families and children",
      "Protection institutionnelle de la famille et de l’enfance"
    ],
    "الدبلوماسية والتعاون": [
      "Diplomacy and cooperation",
      "Diplomatie et coopération"
    ],
    "الدكاء الاصطناعي": [
      "Artificial intelligence",
      "Intelligence artificielle"
    ],
    "الدولة والمجتمع المدني/الحقوق والحريات الاساسية": [
      "State and civil society / Fundamental rights and freedoms",
      "État et société civile / Droits et libertés fondamentaux"
    ],
    "الديموقراطية وحقوق الانسان/الحريات العامة": [
      "Democracy and human rights / Public freedoms",
      "Démocratie et droits humains / Libertés publiques"
    ],
    "الرقابة التسويقية": ["Marketing control", "Contrôle marketing"],
    "الرقابة الجائية والمنازعات": [
      "Tax control and disputes",
      "Contrôle fiscal et contentieux"
    ],
    "الرقابة الجبائية": ["Tax control", "Contrôle fiscal"],
    "الرقابة والتدقيق الجبائي": [
      "Tax control and auditing",
      "Contrôle et audit fiscaux"
    ],
    "السلوك التنظيمي": [
      "Organizational behavior",
      "Comportement organisationnel"
    ],
    "السندات والرخص لمنجمية": [
      "Mining titles and permits",
      "Titres et permis miniers"
    ],
    "السياسات التجارية الدولية": [
      "International trade policies",
      "Politiques commerciales internationales"
    ],
    "السياسات الخارجية والعلاقات الدبلوماسية": [
      "Foreign policies and diplomatic relations",
      "Politiques étrangères et relations diplomatiques"
    ],
    "الصحة والسلامة المهنية": [
      "Occupational health and safety",
      "Santé et sécurité au travail"
    ],
    "الصيرفة الاسلامية": ["Islamic banking", "Banque islamique"],
    "الضرائب المباشرة وغير المباشرة": [
      "Direct and indirect taxes",
      "Impôts directs et indirects"
    ],
    "الطرق البديلة لتسوية النزاعات": [
      "Alternative dispute resolution",
      "Modes alternatifs de règlement des conflits"
    ],
    "العدالة الجنائية الدولية": [
      "International criminal justice",
      "Justice pénale internationale"
    ],
    "العقود الطاقوية": ["Energy contracts", "Contrats énergétiques"],
    "العمليات الجمركية": ["Customs operations", "Opérations douanières"],
    "العولمة والحكومة العالمية": [
      "Globalization and world government",
      "Mondialisation et gouvernement mondial"
    ],
    "الفاعلون غير الحكوميون في العلاقات الدولية/ الجزائر في محيطها الاقليمي والدولي":
        [
      "Non-state actors in international relations / Algeria in its regional and international environment",
      "Acteurs non étatiques des relations internationales / L’Algérie dans son environnement régional et international"
    ],
    "القانون الاداري": ["Administrative law", "Droit administratif"],
    "القانون البحري": ["Maritime law", "Droit maritime"],
    "القانون البنكي": ["Banking law", "Droit bancaire"],
    "القانون الجبائي": ["Tax law", "Droit fiscal"],
    "القانون الجزائي للاعمال": [
      "Business criminal law",
      "Droit pénal des affaires"
    ],
    "القانون الجنائي الخاص": ["Special criminal law", "Droit pénal spécial"],
    "القانون الجنائي الدولي": [
      "International criminal law",
      "Droit pénal international"
    ],
    "القانون الجنائي المقارن": [
      "Comparative criminal law",
      "Droit pénal comparé"
    ],
    "القانون الجنائي للاعمال": [
      "Business criminal law",
      "Droit pénal des affaires"
    ],
    "القانون الحري المعمق": [
      "Advanced maritime law",
      "Droit maritime approfondi"
    ],
    "القانون الدولي الخاص": [
      "Private international law",
      "Droit international privé"
    ],
    "القانون الدولي للبحار": [
      "International law of the sea",
      "Droit international de la mer"
    ],
    "القانون السياحي والفندقي": [
      "Tourism and hotel law",
      "Droit touristique et hôtelier"
    ],
    "القيادة الادارية": [
      "Administrative leadership",
      "Leadership administratif"
    ],
    "اللامركزية والجمهورية": [
      "Decentralization and the republic",
      "Décentralisation et république"
    ],
    "اللسانيات والصوتيات": [
      "Linguistics and phonetics",
      "Linguistique et phonétique"
    ],
    "المؤسسات الدستورية": [
      "Constitutional institutions",
      "Institutions constitutionnelles"
    ],
    "المؤسسات السياسية والادارية في الجزائر": [
      "Political and administrative institutions in Algeria",
      "Institutions politiques et administratives en Algérie"
    ],
    "المالية الدولية المعمقة": [
      "Advanced international finance",
      "Finance internationale approfondie"
    ],
    "المالية المحلية": ["Local finance", "Finances locales"],
    "المجتمع الدولي": ["International community", "Société internationale"],
    "المحاسبة القطاعية": ["Sector accounting", "Comptabilité sectorielle"],
    "المحاسبة المالية المعمقة": [
      "Advanced financial accounting",
      "Comptabilité financière approfondie"
    ],
    "المسؤولية الادارية": [
      "Administrative liability",
      "Responsabilité administrative"
    ],
    "المسؤولية الجنائية": ["Criminal liability", "Responsabilité pénale"],
    "المسؤولية المهنية": [
      "Professional liability",
      "Responsabilité professionnelle"
    ],
    "المشروع المهني والشخصي": [
      "Professional and personal project",
      "Projet professionnel et personnel"
    ],
    "المعايير المحاسبية الدولية": [
      "International accounting standards",
      "Normes comptables internationales"
    ],
    "المفاوضات الدولية": [
      "International negotiations",
      "Négociations internationales"
    ],
    "المقارنة الجديدة في العلاقات الدولية": [
      "New comparative perspectives in international relations",
      "Nouvelles perspectives comparatives en relations internationales"
    ],
    "المقاصد العامة لاحكام الاسرة": [
      "General purposes of family law provisions",
      "Finalités générales des dispositions du droit de la famille"
    ],
    "المقاولاتية": ["Entrepreneurship", "Entrepreneuriat"],
    "المنازعات الادارية": [
      "Administrative disputes",
      "Contentieux administratif"
    ],
    "المنازعات البحرية": ["Maritime disputes", "Contentieux maritime"],
    "المنازعات الدستورية": [
      "Constitutional disputes",
      "Contentieux constitutionnel"
    ],
    "المنظمات الدولية البحرية": [
      "International maritime organizations",
      "Organisations maritimes internationales"
    ],
    "المنهجية": ["Methodology", "Méthodologie"],
    "الميزانية العامة": ["Public budget", "Budget public"],
    "النام التاديبي للموظف العمومي": [
      "Civil service disciplinary system",
      "Régime disciplinaire du fonctionnaire"
    ],
    "النظام القانوني للحقوق البحرية": [
      "Legal framework of maritime rights",
      "Régime juridique des droits maritimes"
    ],
    "النظام المالي والبنكي الجزائري": [
      "Algerian financial and banking system",
      "Système financier et bancaire algérien"
    ],
    "النظريات والسياسات النقدية": [
      "Monetary theories and policies",
      "Théories et politiques monétaires"
    ],
    "النظرية المالية": ["Financial theory", "Théorie financière"],
    "النظم الدبلوماسية والقنصلية": [
      "Diplomatic and consular systems",
      "Systèmes diplomatiques et consulaires"
    ],
    "النظم السياسية الديمقراطية": [
      "Democratic political systems",
      "Systèmes politiques démocratiques"
    ],
    "النمدجة الاحصائية": ["Statistical modeling", "Modélisation statistique"],
    "النيابة الشرعية": ["Legal guardianship", "Représentation légale"],
    "الهندسة المالية": ["Financial engineering", "Ingénierie financière"],
    "الهندسة الوظيفية": ["Job design", "Ingénierie des emplois"],
    "الهوية والمواطنة": ["Identity and citizenship", "Identité et citoyenneté"],
    "الوظيفة العمومية": ["Civil service", "Fonction publique"],
    "اليات تسوية المنازعات الجبائية": [
      "Tax dispute settlement mechanisms",
      "Mécanismes de règlement des litiges fiscaux"
    ],
    "اليات تسوية النزاعات الطاقوية والمنجمية": [
      "Energy and mining dispute settlement mechanisms",
      "Mécanismes de règlement des litiges énergétiques et miniers"
    ],
    "انجليزية": ["English", "Anglais"],
    "انجليزية مهنية": ["Professional English", "Anglais professionnel"],
    "انحلال الرابطة الزوجية": [
      "Dissolution of marriage",
      "Dissolution du lien conjugal"
    ],
    "بحوث التسويق": ["Marketing research", "Études marketing"],
    "برمجيات احصائية": ["Statistical software", "Logiciels statistiques"],
    "برمجيات احصائية حرة": [
      "Free statistical software",
      "Logiciels statistiques libres"
    ],
    "برمجيات التسويق السياحي الالكتروني": [
      "Digital tourism marketing software",
      "Logiciels de marketing touristique numérique"
    ],
    "بلاغة عربية": ["Arabic rhetoric", "Rhétorique arabe"],
    "بورصة البضائع": ["Commodity exchange", "Bourse de marchandises"],
    "تاريخ الجزائر السياسي": [
      "Political history of Algeria",
      "Histoire politique de l’Algérie"
    ],
    "تاريخ الحضارة الانسانية": [
      "History of human civilization",
      "Histoire de la civilisation humaine"
    ],
    "تاريخ العلاقات الدولية": [
      "History of international relations",
      "Histoire des relations internationales"
    ],
    "تاريخ الفكر الاجتماعي": [
      "History of social thought",
      "Histoire de la pensée sociale"
    ],
    "تاريخ الفكر السياسي": [
      "History of political thought",
      "Histoire de la pensée politique"
    ],
    "تاريخ النظم القانونية": [
      "History of legal systems",
      "Histoire des systèmes juridiques"
    ],
    "تاريخ الوقائع الاقتصادية": [
      "Economic history",
      "Histoire des faits économiques"
    ],
    "تاسيس وتحصيل الجباية": [
      "Tax assessment and collection",
      "Établissement et recouvrement de l’impôt"
    ],
    "تجارة ومالية دولية": [
      "International trade and finance",
      "Commerce et finance internationaux"
    ],
    "تحرير اداري": ["Administrative writing", "Rédaction administrative"],
    "تحرير الاتفاقيات المنجمية": [
      "Drafting mining agreements",
      "Rédaction des conventions minières"
    ],
    "تحرير التقارير": ["Report writing", "Rédaction de rapports"],
    "تحرير العقود والعرائض": [
      "Drafting contracts and petitions",
      "Rédaction des contrats et requêtes"
    ],
    "تحرير الوثائق الجبائية": [
      "Drafting tax documents",
      "Rédaction des documents fiscaux"
    ],
    "تحرير عقود النقل البحري للبضائع": [
      "Drafting maritime cargo transport contracts",
      "Rédaction des contrats de transport maritime de marchandises"
    ],
    "تحليل الاستراتيجي والتنافسي": [
      "Strategic and competitive analysis",
      "Analyse stratégique et concurrentielle"
    ],
    "تحليل البيانات": ["Data analysis", "Analyse des données"],
    "تحليل البيانات التسويقية": [
      "Marketing data analysis",
      "Analyse des données marketing"
    ],
    "تحليل الخطاب السياسي": [
      "Political discourse analysis",
      "Analyse du discours politique"
    ],
    "تحليل السلاسل الزمنية": [
      "Time series analysis",
      "Analyse des séries chronologiques"
    ],
    "تحليل السياسات الخارجية": [
      "Foreign policy analysis",
      "Analyse des politiques étrangères"
    ],
    "تحليل السياسة الخارجية": [
      "Foreign policy analysis",
      "Analyse de la politique étrangère"
    ],
    "تحليل المدخلات والمخرجات": [
      "Input-output analysis",
      "Analyse entrées-sorties"
    ],
    "تحليل النزاعات الدولية": [
      "International conflict analysis",
      "Analyse des conflits internationaux"
    ],
    "تحليل الوثائق الدبلوماسية": [
      "Diplomatic document analysis",
      "Analyse des documents diplomatiques"
    ],
    "تخطيط موارد المؤسسة ERP": [
      "Enterprise resource planning (ERP)",
      "Planification des ressources de l’entreprise (ERP)"
    ],
    "تدقيق محاسبي": ["Accounting audit", "Audit comptable"],
    "تسويق الخدمات": ["Services marketing", "Marketing des services"],
    "تسويق الخدمات الصحية": [
      "Healthcare services marketing",
      "Marketing des services de santé"
    ],
    "تسويق الخدمات العمومية": [
      "Public services marketing",
      "Marketing des services publics"
    ],
    "تسويق الخدمات المالية": [
      "Financial services marketing",
      "Marketing des services financiers"
    ],
    "تسويق الخدمات المالية والبنكية": [
      "Financial and banking services marketing",
      "Marketing des services financiers et bancaires"
    ],
    "تسويق خدمات النقل": [
      "Transport services marketing",
      "Marketing des services de transport"
    ],
    "تسويق فندقي وسياحي": [
      "Hotel and tourism marketing",
      "Marketing hôtelier et touristique"
    ],
    "تسيير المؤسسة": ["Business management", "Gestion de l’entreprise"],
    "تسيير المالي": ["Financial management", "Gestion financière"],
    "تسيير المحافظ المالية": [
      "Financial portfolio management",
      "Gestion des portefeuilles financiers"
    ],
    "تسيير المحفظة المالية": [
      "Financial portfolio management",
      "Gestion de portefeuille financier"
    ],
    "تسيير الوارد البشرية": [
      "Human resources management",
      "Gestion des ressources humaines"
    ],
    "تطبيق علاقات العمل والمنازعات الاجتماعية": [
      "Labor relations and social dispute practice",
      "Pratique des relations de travail et des conflits sociaux"
    ],
    "تطبيقات الاجراءات الجزائية": [
      "Criminal procedure practice",
      "Pratique de la procédure pénale"
    ],
    "تطبيقات التعلم العميق": [
      "Deep learning applications",
      "Applications de l’apprentissage profond"
    ],
    "تطبيقات التنفيد والبيوع القضائية": [
      "Enforcement and judicial sale practice",
      "Pratique de l’exécution et des ventes judiciaires"
    ],
    "تطبيقات الدعاوى الاجرائية": [
      "Procedural action practice",
      "Pratique des actions procédurales"
    ],
    "تطبيقات الدعاوى المدنية والادارية": [
      "Civil and administrative action practice",
      "Pratique des actions civiles et administratives"
    ],
    "تطبيقات العقود": ["Contract practice", "Pratique des contrats"],
    "تطبيقات في التسويق الرقمي": [
      "Digital marketing applications",
      "Applications du marketing numérique"
    ],
    "تقنيات الاستقصاء": ["Survey techniques", "Techniques d’enquête"],
    "تقنيات البحث": ["Research techniques", "Techniques de recherche"],
    "تقنيات البحث العلمي": [
      "Scientific research techniques",
      "Techniques de recherche scientifique"
    ],
    "تقنيات البنوك والتامينات": [
      "Banking and insurance techniques",
      "Techniques bancaires et d’assurance"
    ],
    "تقنيات التجارة الدولية": [
      "International trade techniques",
      "Techniques du commerce international"
    ],
    "تقنيات التحرير الاداري": [
      "Administrative writing techniques",
      "Techniques de rédaction administrative"
    ],
    "تقنيات التعبير الشفوي": [
      "Oral expression techniques",
      "Techniques d’expression orale"
    ],
    "تقنيات التعبير الكتابي": [
      "Written expression techniques",
      "Techniques d’expression écrite"
    ],
    "تقنيات التفاوض": ["Negotiation techniques", "Techniques de négociation"],
    "تقنيات العمل الجامعي": [
      "Academic work techniques",
      "Techniques du travail universitaire"
    ],
    "تقنيات الميزانية": ["Budgeting techniques", "Techniques budgétaires"],
    "تقنيات بنكية": ["Banking techniques", "Techniques bancaires"],
    "تقنيات تحرير العرائض": [
      "Petition drafting techniques",
      "Techniques de rédaction des requêtes"
    ],
    "تقنيات تسيير البورصة": [
      "Stock exchange management techniques",
      "Techniques de gestion boursière"
    ],
    "تقنيات تمويل التجارة الخارجية": [
      "Foreign trade financing techniques",
      "Techniques de financement du commerce extérieur"
    ],
    "تقنيات واعمال البنوك": [
      "Banking techniques and operations",
      "Techniques et opérations bancaires"
    ],
    "تقييم المشاريع": ["Project evaluation", "Évaluation de projets"],
    "تكنلوجيا الاعلام والاتصال": [
      "Information and communication technology",
      "Technologies de l’information et de la communication"
    ],
    "تكنلوجيا مالية والدكاء الاصطناعي": [
      "Financial technology and artificial intelligence",
      "Technologie financière et intelligence artificielle"
    ],
    "تكنلوجيات الاعلام والاتصال والتعليم الالكتروني": [
      "ICT and e-learning",
      "TIC et enseignement en ligne"
    ],
    "تكنولوجيا الاعلام والاتصال": [
      "Information and communication technology",
      "Technologies de l’information et de la communication"
    ],
    "تكنولوجيات الاعلام والاتصال والتعليم الالكتروني": [
      "ICT and e-learning",
      "TIC et enseignement en ligne"
    ],
    "تنازع القوانين في مسائل الاسرة": [
      "Conflict of laws in family matters",
      "Conflits de lois en matière familiale"
    ],
    "تنظيم قضائي": ["Judicial organization", "Organisation judiciaire"],
    "تنظيم واخلاقيات مهنة المحاسبة": [
      "Organization and ethics of the accounting profession",
      "Organisation et déontologie de la profession comptable"
    ],
    "ثقافة المنظمة": ["Organizational culture", "Culture organisationnelle"],
    "جباية المؤسسة": ["Business taxation", "Fiscalité de l’entreprise"],
    "جباية المحروقات": ["Hydrocarbon taxation", "Fiscalité des hydrocarbures"],
    "جرائم الفساد": ["Corruption offenses", "Infractions de corruption"],
    "جرائم الفساد ومكافحته": [
      "Corruption offenses and prevention",
      "Infractions de corruption et lutte contre la corruption"
    ],
    "جمركة السلع والبضائع": [
      "Customs clearance of goods",
      "Dédouanement des marchandises"
    ],
    "جيوسياسية العلاقات الدولية": [
      "Geopolitics of international relations",
      "Géopolitique des relations internationales"
    ],
    "حريات وحقوق اساسية": [
      "Fundamental rights and freedoms",
      "Libertés et droits fondamentaux"
    ],
    "حضارات": ["Civilizations", "Civilisations"],
    "حضارة وثقافة والتفاعل الثقافي": [
      "Civilization, culture and cultural interaction",
      "Civilisation, culture et interaction culturelle"
    ],
    "حقوق الانسان": ["Human rights", "Droits humains"],
    "حوكمة الشركات": ["Corporate governance", "Gouvernance d’entreprise"],
    "حوكمة لشركات": ["Corporate governance", "Gouvernance d’entreprise"],
    "دراسة نصوص ادبية": [
      "Study of literary texts",
      "Étude de textes littéraires"
    ],
    "دراسة وتقييم المشاريع الاستثمارية": [
      "Investment project analysis and evaluation",
      "Étude et évaluation des projets d’investissement"
    ],
    "دعاوى شؤون الاسرة": [
      "Family law proceedings",
      "Actions en matière familiale"
    ],
    "دكاء الاعمال وتنافسة المنظمات": [
      "Business intelligence and organizational competitiveness",
      "Intelligence économique et compétitivité des organisations"
    ],
    "دكاء الاعمال وتنافسية المنظمات": [
      "Business intelligence and organizational competitiveness",
      "Intelligence économique et compétitivité des organisations"
    ],
    "رجال البحر": ["Seafarers", "Gens de mer"],
    "ريادة الأعمال": ["Entrepreneurship", "Entrepreneuriat"],
    "رياضيات": ["Mathematics", "Mathématiques"],
    "رياضيات مالية": ["Financial mathematics", "Mathématiques financières"],
    "سلاسل القيمة العالمية": [
      "Global value chains",
      "Chaînes de valeur mondiales"
    ],
    "سلطات الضبط المستقلة": [
      "Independent regulatory authorities",
      "Autorités de régulation indépendantes"
    ],
    "سلوك المستهلك": ["Consumer behavior", "Comportement du consommateur"],
    "سلوك المستهلك السياحي": [
      "Tourist consumer behavior",
      "Comportement du consommateur touristique"
    ],
    "سياسات التنمية المحلية": [
      "Local development policies",
      "Politiques de développement local"
    ],
    "شركات الاموال": ["Capital companies", "Sociétés de capitaux"],
    "شركات تجارية": ["Commercial companies", "Sociétés commerciales"],
    "صناعة القرارات وادرة الازمات": [
      "Decision-making and crisis management",
      "Prise de décision et gestion des crises"
    ],
    "صنع وتنفيد السياسات العامة": [
      "Public policy formulation and implementation",
      "Élaboration et mise en œuvre des politiques publiques"
    ],
    "طرق الاثبات في قانون الاسرة": [
      "Methods of proof in family law",
      "Modes de preuve en droit de la famille"
    ],
    "طرق الاثبات والتنفيد": [
      "Methods of proof and enforcement",
      "Modes de preuve et d’exécution"
    ],
    "عروض وموسيقى الشعر": [
      "Prosody and poetic rhythm",
      "Prosodie et musicalité poétique"
    ],
    "عقد الزواج واثاره": [
      "Marriage contract and its effects",
      "Contrat de mariage et ses effets"
    ],
    "عقد النقل البحري للضائع": [
      "Maritime cargo transport contract",
      "Contrat de transport maritime de marchandises"
    ],
    "عقود الاعمال": ["Business contracts", "Contrats d’affaires"],
    "عقود خاصة": ["Special contracts", "Contrats spéciaux"],
    "علم الاجتماع الاسري": ["Family sociology", "Sociologie de la famille"],
    "علم الاجرام المعمق": ["Advanced criminology", "Criminologie approfondie"],
    "علم الصرف": ["Morphology", "Morphologie"],
    "علم الفرائض": ["Inheritance shares", "Science des parts successorales"],
    "علم النحو": ["Grammar", "Grammaire"],
    "علوم القرءان": ["Quranic studies", "Sciences du Coran"],
    "عمليات الخزينة": ["Treasury operations", "Opérations de trésorerie"],
    "فقه اللغة": ["Philology", "Philologie"],
    "فهم وتعبير شفويان": [
      "Oral comprehension and expression",
      "Compréhension et expression orales"
    ],
    "فهم وتعبير كتابيان": [
      "Written comprehension and expression",
      "Compréhension et expression écrites"
    ],
    "قانون اداري": ["Administrative law", "Droit administratif"],
    "قانون الاجراءات الجنائية": [
      "Criminal procedure law",
      "Droit de la procédure pénale"
    ],
    "قانون الاجراءات الجنائية المعمق": [
      "Advanced criminal procedure law",
      "Droit de la procédure pénale approfondi"
    ],
    "قانون الادارة المينائية": [
      "Port administration law",
      "Droit de l’administration portuaire"
    ],
    "قانون الاساسي للوظيفة العمومية": [
      "Civil service statute",
      "Statut de la fonction publique"
    ],
    "قانون الاستثمار": ["Investment law", "Droit de l’investissement"],
    "قانون الاستهلاك": ["Consumer law", "Droit de la consommation"],
    "قانون الاسواق المالية": [
      "Financial markets law",
      "Droit des marchés financiers"
    ],
    "قانون الاعمال": ["Business law", "Droit des affaires"],
    "قانون الاقتصاد العام": ["Public economic law", "Droit public économique"],
    "قانون الاملاك الوطنية": [
      "National property law",
      "Droit des biens nationaux"
    ],
    "قانون البيئة": ["Environmental law", "Droit de l’environnement"],
    "قانون التامين": ["Insurance law", "Droit des assurances"],
    "قانون التجارة الخارجية": [
      "Foreign trade law",
      "Droit du commerce extérieur"
    ],
    "قانون التجارة الدولية": [
      "International trade law",
      "Droit du commerce international"
    ],
    "قانون الجمارك": ["Customs law", "Droit douanier"],
    "قانون الحالة المدنية": ["Civil status law", "Droit de l’état civil"],
    "قانون الدفع الالكتروني": [
      "Electronic payment law",
      "Droit du paiement électronique"
    ],
    "قانون الدولي العام": [
      "Public international law",
      "Droit international public"
    ],
    "قانون الشركات": ["Company law", "Droit des sociétés"],
    "قانون الصفقات العمومية": [
      "Public procurement law",
      "Droit des marchés publics"
    ],
    "قانون الضرائب": ["Tax law", "Droit fiscal"],
    "قانون الطاقة والطاقة المتجددة": [
      "Energy and renewable energy law",
      "Droit de l’énergie et des énergies renouvelables"
    ],
    "قانون العمل": ["Labor law", "Droit du travail"],
    "قانون المرافق العامة": [
      "Public service law",
      "Droit des services publics"
    ],
    "قانون الملاحة البحرية": [
      "Maritime navigation law",
      "Droit de la navigation maritime"
    ],
    "قانون الملكية الفكرية": [
      "Intellectual property law",
      "Droit de la propriété intellectuelle"
    ],
    "قانون المناجم": ["Mining law", "Droit minier"],
    "قانون المنافسة": ["Competition law", "Droit de la concurrence"],
    "قانون المنافسة وحماية المستهلك": [
      "Competition and consumer protection law",
      "Droit de la concurrence et de la protection du consommateur"
    ],
    "قانون الميزانية": ["Budget law", "Droit budgétaire"],
    "قانون بحري": ["Maritime law", "Droit maritime"],
    "قانون تجاري": ["Commercial law", "Droit commercial"],
    "قانون تنظيم المؤسسات العقابية": [
      "Law on the organization of penal institutions",
      "Droit de l’organisation des établissements pénitentiaires"
    ],
    "قانون جنائي خاص وجرائم الفساد": [
      "Special criminal law and corruption offenses",
      "Droit pénal spécial et infractions de corruption"
    ],
    "قانون جنائي عام": ["General criminal law", "Droit pénal général"],
    "قانون حماية البيئة البحرية": [
      "Marine environmental protection law",
      "Droit de la protection de l’environnement marin"
    ],
    "قانون حماية البيئة والامن الصناعي": [
      "Environmental protection and industrial safety law",
      "Droit de la protection de l’environnement et de la sécurité industrielle"
    ],
    "قانون دبلوماسي وقنصلي": [
      "Diplomatic and consular law",
      "Droit diplomatique et consulaire"
    ],
    "قانون دستوري": ["Constitutional law", "Droit constitutionnel"],
    "قانون دولي انساني": [
      "International humanitarian law",
      "Droit international humanitaire"
    ],
    "قانون دولي خاص": [
      "Private international law",
      "Droit international privé"
    ],
    "قانون دولي عام": [
      "Public international law",
      "Droit international public"
    ],
    "قانون ديستوري": ["Constitutional law", "Droit constitutionnel"],
    "قانون مدني": ["Civil law", "Droit civil"],
    "قانون مقارن": ["Comparative law", "Droit comparé"],
    "قانون مكافحة الفساد": [
      "Anti-corruption law",
      "Droit de la lutte contre la corruption"
    ],
    "قانون وتشريع العمل": [
      "Labor law and legislation",
      "Droit et législation du travail"
    ],
    "قراءة ودراسة النصوص": [
      "Reading and text study",
      "Lecture et étude de textes"
    ],
    "قرارات وعقود ادارية": [
      "Administrative decisions and contracts",
      "Décisions et contrats administratifs"
    ],
    "قضاء الاحداث": ["Juvenile justice", "Justice des mineurs"],
    "قضايا الاسرة في القانون الدولي": [
      "Family matters in international law",
      "Questions familiales en droit international"
    ],
    "لسانيات": ["Linguistics", "Linguistique"],
    "لغ.انج. للابحاث وكتابة المدكرات": [
      "English for research and dissertation writing",
      "Anglais pour la recherche et la rédaction de mémoires"
    ],
    "لغ.انج.للابحاث وكتابة المدكرات": [
      "English for research and dissertation writing",
      "Anglais pour la recherche et la rédaction de mémoires"
    ],
    "لغات": ["Languages", "Langues"],
    "لغة أجنبية": ["Foreign language", "Langue étrangère"],
    "لغة اجنبية": ["Foreign language", "Langue étrangère"],
    "لغة اجنبية 1 & البرمجة": [
      "Foreign language 1 and programming",
      "Langue étrangère 1 et programmation"
    ],
    "لغة اجنبية متخصصة": [
      "Specialized foreign language",
      "Langue étrangère spécialisée"
    ],
    "لغة اجنبيةة": ["Foreign language", "Langue étrangère"],
    "م.اعداد مدكرة الماستر": [
      "Master’s dissertation methodology",
      "Méthodologie du mémoire de master"
    ],
    "مؤسسات الطاقة والمنجم": [
      "Energy and mining institutions",
      "Institutions de l’énergie et des mines"
    ],
    "مالية المؤسسة": ["Corporate finance", "Finance d’entreprise"],
    "مالية دولية": ["International finance", "Finance internationale"],
    "مالية عمومية": ["Public finance", "Finances publiques"],
    "مالية وتجارة دولية": [
      "International finance and trade",
      "Finance et commerce internationaux"
    ],
    "مجلس المحاسبة": ["Court of Auditors", "Cour des comptes"],
    "محاسبة البنوك والتامينات": [
      "Banking and insurance accounting",
      "Comptabilité bancaire et des assurances"
    ],
    "محاسبة التسيير": ["Management accounting", "Comptabilité de gestion"],
    "محاسبة الشركات": ["Company accounting", "Comptabilité des sociétés"],
    "محاسبة الشركات المعمقة": [
      "Advanced company accounting",
      "Comptabilité approfondie des sociétés"
    ],
    "محاسبة تسيير": ["Management accounting", "Comptabilité de gestion"],
    "محاسبة عمومية": ["Public accounting", "Comptabilité publique"],
    "محاسبة مالية": ["Financial accounting", "Comptabilité financière"],
    "محاسبة مالية معمقة": [
      "Advanced financial accounting",
      "Comptabilité financière approfondie"
    ],
    "مدخل الاقتصاد": ["Introduction to economics", "Introduction à l’économie"],
    "مدخل الى الاحصاء": [
      "Introduction to statistics",
      "Introduction aux statistiques"
    ],
    "مدخل الى التعليمة": [
      "Introduction to didactics",
      "Introduction à la didactique"
    ],
    "مدخل لادارة الاعمال": [
      "Introduction to business administration",
      "Introduction à la gestion des entreprises"
    ],
    "مدخل لعلم اجتماع المنظمات": [
      "Introduction to organizational sociology",
      "Introduction à la sociologie des organisations"
    ],
    "مدخل لعلم الاجتماع": [
      "Introduction to sociology",
      "Introduction à la sociologie"
    ],
    "مدخل لعلم الادارة": [
      "Introduction to administrative science",
      "Introduction à la science administrative"
    ],
    "مدخل لعلم السياسة": [
      "Introduction to political science",
      "Introduction à la science politique"
    ],
    "مدخل للبايثون": ["Introduction to Python", "Introduction à Python"],
    "مدخل للتعاون الدولي": [
      "Introduction to international cooperation",
      "Introduction à la coopération internationale"
    ],
    "مدخل للشريعة الاسلامية": [
      "Introduction to Islamic law",
      "Introduction au droit islamique"
    ],
    "مدخل للعلاقات الدولية": [
      "Introduction to international relations",
      "Introduction aux relations internationales"
    ],
    "مدخل للعلوم القانونية": [
      "Introduction to legal studies",
      "Introduction aux sciences juridiques"
    ],
    "مدخل للقانون": ["Introduction to law", "Introduction au droit"],
    "مدخل للقانون الجبائي": [
      "Introduction to tax law",
      "Introduction au droit fiscal"
    ],
    "مراقبة التسيير": ["Management control", "Contrôle de gestion"],
    "مراقبة التسيير الاجتماعي": [
      "Social management control",
      "Contrôle de gestion sociale"
    ],
    "مراقبة التسيير المعمقة": [
      "Advanced management control",
      "Contrôle de gestion approfondi"
    ],
    "مشروع التخرج": ["Graduation project", "Projet de fin d’études"],
    "مصادر اللغة والادب والنقد": [
      "Sources of language, literature and criticism",
      "Sources de la langue, de la littérature et de la critique"
    ],
    "معايي اعداد التقارير الماية الدولة IFRS": [
      "International financial reporting standards (IFRS)",
      "Normes internationales d’information financière (IFRS)"
    ],
    "معايير اعدات التقارير المالية الدولية IFRS": [
      "International financial reporting standards (IFRS)",
      "Normes internationales d’information financière (IFRS)"
    ],
    "مقاولاتية": ["Entrepreneurship", "Entrepreneuriat"],
    "مكافحة الفساد واخلاقيات المهن": [
      "Anti-corruption and professional ethics",
      "Lutte contre la corruption et déontologie professionnelle"
    ],
    "ملتقى ادارة المدينة والتهيئة العمرانية": [
      "City management and urban planning seminar",
      "Séminaire de gestion urbaine et d’aménagement du territoire"
    ],
    "ملتقى الجماعات المحلية": [
      "Local government seminar",
      "Séminaire sur les collectivités locales"
    ],
    "ملتقى الحكومة الالكترونية": [
      "E-government seminar",
      "Séminaire sur le gouvernement électronique"
    ],
    "ملتقى الوظيفة العامة بالجزائر": [
      "Algerian civil service seminar",
      "Séminaire sur la fonction publique en Algérie"
    ],
    "ممارسة التواصل الشفوي": [
      "Oral communication practice",
      "Pratique de la communication orale"
    ],
    "منازعات الصفقات العمومية": [
      "Public procurement disputes",
      "Contentieux des marchés publics"
    ],
    "منازعات العمل": ["Labor disputes", "Contentieux du travail"],
    "منظمات الطاقة الدولية": [
      "International energy organizations",
      "Organisations internationales de l’énergie"
    ],
    "منهجية اعداد المندكرة": [
      "Dissertation methodology",
      "Méthodologie du mémoire"
    ],
    "منهجية اعداد مدكر الماستر": [
      "Master’s dissertation methodology",
      "Méthodologie du mémoire de master"
    ],
    "منهجية اعداد مدكرة التخرج": [
      "Graduation dissertation methodology",
      "Méthodologie du mémoire de fin d’études"
    ],
    "منهجية اعداد مدكرة الماستار": [
      "Master’s dissertation methodology",
      "Méthodologie du mémoire de master"
    ],
    "منهجية اعداد مدكرة الماستر": [
      "Master’s dissertation methodology",
      "Méthodologie du mémoire de master"
    ],
    "منهجية البحث الجامعي": [
      "Academic research methodology",
      "Méthodologie de la recherche universitaire"
    ],
    "منهجية البحث العلمي": [
      "Scientific research methodology",
      "Méthodologie de la recherche scientifique"
    ],
    "منهجية البحث في العلوم السياسية": [
      "Political science research methodology",
      "Méthodologie de la recherche en science politique"
    ],
    "منهجية التحرير الاداري و القضائي": [
      "Administrative and judicial writing methodology",
      "Méthodologie de la rédaction administrative et judiciaire"
    ],
    "منهجية العلوم القانونية": [
      "Legal studies methodology",
      "Méthodologie des sciences juridiques"
    ],
    "منهجية العلوم القانوية": [
      "Legal studies methodology",
      "Méthodologie des sciences juridiques"
    ],
    "منهجية الممارسة المهنية": [
      "Professional practice methodology",
      "Méthodologie de la pratique professionnelle"
    ],
    "منهجيةاعداد مدكرة الماستر": [
      "Master’s dissertation methodology",
      "Méthodologie du mémoire de master"
    ],
    "مهارات القراءة والكتابة الرقمية": [
      "Digital reading and writing skills",
      "Compétences en lecture et écriture numériques"
    ],
    "نحو انجليزي": ["English grammar", "Grammaire anglaise"],
    "نحو فرنسي": ["French grammar", "Grammaire française"],
    "ندوة حول ادارة الموارد البشرية": [
      "Human resources management seminar",
      "Séminaire sur la gestion des ressources humaines"
    ],
    "ندوة في ادارة الاعمال": [
      "Business administration seminar",
      "Séminaire en gestion des entreprises"
    ],
    "ندوة في الادارة المالية": [
      "Financial management seminar",
      "Séminaire en gestion financière"
    ],
    "ندوة في التسويق الياحي والفندقي": [
      "Tourism and hotel marketing seminar",
      "Séminaire en marketing touristique et hôtelier"
    ],
    "ندوة في الجباية": ["Taxation seminar", "Séminaire de fiscalité"],
    "ندوة في تسويق الخدمات": [
      "Services marketing seminar",
      "Séminaire en marketing des services"
    ],
    "نص ادبي قديم": ["Classical literary text", "Texte littéraire ancien"],
    "نظريات التجارة الدولية": [
      "International trade theories",
      "Théories du commerce international"
    ],
    "نظريات التجارة الدولية الحديثة": [
      "Modern international trade theories",
      "Théories modernes du commerce international"
    ],
    "نظريات التنظيم والتسيير": [
      "Organization and management theories",
      "Théories de l’organisation et de la gestion"
    ],
    "نظريات وسياسات التعاون الدولي": [
      "International cooperation theories and policies",
      "Théories et politiques de la coopération internationale"
    ],
    "نظريات وسياسات التنمية": [
      "Development theories and policies",
      "Théories et politiques du développement"
    ],
    "نظرية الادارة المحلية": [
      "Local administration theory",
      "Théorie de l’administration locale"
    ],
    "نظرية التنظيم والتسيير": [
      "Organization and management theory",
      "Théorie de l’organisation et de la gestion"
    ],
    "نظرية الدولة": ["Theory of the state", "Théorie de l’État"],
    "نظرية العلاقات الدوية": [
      "International relations theory",
      "Théorie des relations internationales"
    ],
    "نظرية المحاسبة": ["Accounting theory", "Théorie comptable"],
    "نظرية المنظمة": ["Organization theory", "Théorie de l’organisation"],
    "نظم المعلومات الإدارية": [
      "Management information systems",
      "Systèmes d’information de gestion"
    ],
    "نظم سياسية مقارنة": [
      "Comparative political systems",
      "Systèmes politiques comparés"
    ],
    "نقد ادبي قديم": [
      "Classical literary criticism",
      "Critique littéraire ancienne"
    ],
    "نمادج التوازن العام": [
      "General equilibrium models",
      "Modèles d’équilibre général"
    ],
    "هندسة التكوين": ["Training engineering", "Ingénierie de la formation"],
    "هيئات التعاون الدولي": [
      "International cooperation bodies",
      "Organismes de coopération internationale"
    ],
    "هياكل وتنظيم المؤسسات": [
      "Business structures and organization",
      "Structures et organisation des entreprises"
    ],
    "ورشة القراءة والكتابة": [
      "Reading and writing workshop",
      "Atelier de lecture et d’écriture"
    ],
    "وسائل وانظمة الدفع": [
      "Payment instruments and systems",
      "Moyens et systèmes de paiement"
    ],
    "وكالتا الضبط في قطاع الطاقة والمناجم": [
      "Regulatory agencies in energy and mining",
      "Agences de régulation de l’énergie et des mines"
    ],
  };
}
