from rest_framework import serializers
from .models import Vehicle, MaintenanceRecord, Expense


class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = ["id", "nickname", "make", "model", "year", "current_odometer_km", "fuel_type", "transmission", "created_at", "updated_at"]
        read_only_fields = ["id", "created_at", "updated_at"]

    def validate_year(self, value):
        # Accept both Gregorian and Jalali/Persian calendar years.
        if value is not None:
            jalali = 1300 <= value <= 1500
            gregorian = 1885 <= value <= 2200
            if not (jalali or gregorian):
                raise serializers.ValidationError("سال ساخت معتبر نیست.")
        return value


class MaintenanceRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = MaintenanceRecord
        fields = ["id", "vehicle", "category", "title", "service_date", "odometer_km", "cost", "currency", "notes", "created_at"]
        read_only_fields = ["id", "created_at"]

    def validate(self, attrs):
        vehicle = attrs.get("vehicle", getattr(self.instance, "vehicle", None))
        odo = attrs.get("odometer_km")
        if vehicle and odo is not None and odo > vehicle.current_odometer_km:
            raise serializers.ValidationError({"odometer_km": "کیلومتر ثبت‌شده نمی‌تواند از کیلومتر فعلی خودرو بیشتر باشد."})
        cost = attrs.get("cost")
        if cost is not None and cost < 0:
            raise serializers.ValidationError({"cost": "هزینه نمی‌تواند منفی باشد."})
        return attrs


class ExpenseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Expense
        fields = ["id", "vehicle", "category", "title", "amount", "currency", "expense_date", "odometer_km", "notes", "created_at"]
        read_only_fields = ["id", "created_at"]

    def validate_amount(self, value):
        if value < 0:
            raise serializers.ValidationError("مبلغ نمی‌تواند منفی باشد.")
        return value

    def validate(self, attrs):
        vehicle = attrs.get("vehicle", getattr(self.instance, "vehicle", None))
        odo = attrs.get("odometer_km")
        if vehicle and odo is not None and odo > vehicle.current_odometer_km:
            raise serializers.ValidationError({"odometer_km": "کیلومتر ثبت‌شده نمی‌تواند از کیلومتر فعلی خودرو بیشتر باشد."})
        return attrs
