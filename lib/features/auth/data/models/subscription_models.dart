// subscription_models.dart (or add to auth_models.dart)

class SubscriptionDetailsModel {
  final String? subName;
  final String? subscriptionPlanType;
  final String? subscriptionPlanStartDate;
  final String? subscriptionPlanEndDate;
  final SubscriptionDurationModel? subscriptionDuration;
  final DiscountModel? discount;
  final String? finalPricePaid;
  final bool? autoRenew;
  final String? status;

  const SubscriptionDetailsModel({
    this.subName,
    this.subscriptionPlanType,
    this.subscriptionPlanStartDate,
    this.subscriptionPlanEndDate,
    this.subscriptionDuration,
    this.discount,
    this.finalPricePaid,
    this.autoRenew,
    this.status,
  });

  factory SubscriptionDetailsModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionDetailsModel(
      subName: json['subName'],
      subscriptionPlanType: json['subscriptionPlanType'],
      subscriptionPlanStartDate: json['subscriptionPlanStartDate'],
      subscriptionPlanEndDate: json['subscriptionPlanEndDate'],
      subscriptionDuration: json['subscriptionDuration'] != null
          ? SubscriptionDurationModel.fromJson(json['subscriptionDuration'])
          : null,
      discount: json['discount'] != null
          ? DiscountModel.fromJson(json['discount'])
          : null,
      finalPricePaid: json['finalPricePaid'],
      autoRenew: json['autoRenew'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subName': subName,
      'subscriptionPlanType': subscriptionPlanType,
      'subscriptionPlanStartDate': subscriptionPlanStartDate,
      'subscriptionPlanEndDate': subscriptionPlanEndDate,
      'subscriptionDuration': subscriptionDuration?.toJson(),
      'discount': discount?.toJson(),
      'finalPricePaid': finalPricePaid,
      'autoRenew': autoRenew,
      'status': status,
    };
  }
}

class SubscriptionDurationModel {
  final String? type;
  final int? duration;

  const SubscriptionDurationModel({this.type, this.duration});

  factory SubscriptionDurationModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionDurationModel(
      type: json['type'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'duration': duration};
  }
}

class DiscountModel {
  final String? discountType;
  final String? discountValue;

  const DiscountModel({this.discountType, this.discountValue});

  factory DiscountModel.fromJson(Map<String, dynamic> json) {
    return DiscountModel(
      discountType: json['discountType'],
      discountValue: json['discountValue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'discountType': discountType, 'discountValue': discountValue};
  }
}

class ApplicableModulesModel {
  final List<ModuleModel>? modules;

  const ApplicableModulesModel({this.modules});

  factory ApplicableModulesModel.fromJson(Map<String, dynamic> json) {
    return ApplicableModulesModel(
      modules: (json['modules'] as List<dynamic>?)
          ?.map((e) => ModuleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'modules': modules?.map((e) => e.toJson()).toList()};
  }
}

class ModuleModel {
  final int? moduleId;
  final String? moduleName;
  final String? moduleCode;
  final String? moduleDescription;
  final String? unitPriceAtPurchase;
  final String? discountPercentage;
  final String? discountAmount;

  const ModuleModel({
    this.moduleId,
    this.moduleName,
    this.moduleCode,
    this.moduleDescription,
    this.unitPriceAtPurchase,
    this.discountPercentage,
    this.discountAmount,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      moduleId: json['moduleId'],
      moduleName: json['moduleName'],
      moduleCode: json['moduleCode'],
      moduleDescription: json['moduleDescription'],
      unitPriceAtPurchase: json['unitPriceAtPurchase'],
      discountPercentage: json['discountPercentage'],
      discountAmount: json['discountAmount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleId': moduleId,
      'moduleName': moduleName,
      'moduleCode': moduleCode,
      'moduleDescription': moduleDescription,
      'unitPriceAtPurchase': unitPriceAtPurchase,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
    };
  }
}

class PaymentMadeModel {
  final String? totalBasePrice;
  final String? totalDiscountAmount;
  final String? finalPayableAmount;
  final CurrencyModel? currency;
  final String? paymentMethod;
  final String? paymentStatus;

  const PaymentMadeModel({
    this.totalBasePrice,
    this.totalDiscountAmount,
    this.finalPayableAmount,
    this.currency,
    this.paymentMethod,
    this.paymentStatus,
  });

  factory PaymentMadeModel.fromJson(Map<String, dynamic> json) {
    return PaymentMadeModel(
      totalBasePrice: json['totalBasePrice'],
      totalDiscountAmount: json['totalDiscountAmount'],
      finalPayableAmount: json['finalPayableAmount'],
      currency: json['currency'] != null
          ? CurrencyModel.fromJson(json['currency'])
          : null,
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBasePrice': totalBasePrice,
      'totalDiscountAmount': totalDiscountAmount,
      'finalPayableAmount': finalPayableAmount,
      'currency': currency?.toJson(),
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
    };
  }
}

class CurrencyModel {
  final int? id;
  final String? name;
  final String? code;

  const CurrencyModel({this.id, this.name, this.code});

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'code': code};
  }
}

class SubscriptionPlanModel {
  final SubscriptionDetailsModel subscription;
  final ApplicableModulesModel applicableModules;
  final PaymentMadeModel paymentMade;

  const SubscriptionPlanModel({
    required this.subscription,
    required this.applicableModules,
    required this.paymentMade,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      subscription: SubscriptionDetailsModel.fromJson(json['subscription']),
      applicableModules: ApplicableModulesModel.fromJson(
        json['applicableModules'],
      ),
      paymentMade: PaymentMadeModel.fromJson(json['paymentMade']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscription': subscription.toJson(),
      'applicableModules': applicableModules.toJson(),
      'paymentMade': paymentMade.toJson(),
    };
  }
}

class SubscriptionsModel {
  final List<SubscriptionPlanModel>? activePlans;
  final List<SubscriptionPlanModel>? expiringSoonPlans;
  final List<SubscriptionPlanModel>? expiredPlans;

  const SubscriptionsModel({
    this.activePlans,
    this.expiringSoonPlans,
    this.expiredPlans,
  });

  factory SubscriptionsModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionsModel(
      activePlans: (json['activePlans'] as List<dynamic>?)
          ?.map(
            (e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      expiringSoonPlans: (json['expiringSoonPlans'] as List<dynamic>?)
          ?.map(
            (e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      expiredPlans: (json['expiredPlans'] as List<dynamic>?)
          ?.map(
            (e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activePlans': activePlans?.map((e) => e.toJson()).toList(),
      'expiringSoonPlans': expiringSoonPlans?.map((e) => e.toJson()).toList(),
      'expiredPlans': expiredPlans?.map((e) => e.toJson()).toList(),
    };
  }
}
