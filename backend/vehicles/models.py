from django.conf import settings
from django.db import models


class Vehicle(models.Model):
    FUEL_CHOICES = [
        ("petrol", "بنزین"),
        ("diesel", "گازوئیل"),
        ("hybrid", "هیبرید"),
        ("electric", "برقی"),
        ("lpg", "گاز مایع"),
        ("cng", "گاز طبیعی"),
        ("other", "سایر"),
    ]
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="vehicles")
    nickname = models.CharField(max_length=80, blank=True)
    make = models.CharField(max_length=80)
    model = models.CharField(max_length=80)
    year = models.PositiveSmallIntegerField(null=True, blank=True)
    current_odometer_km = models.PositiveIntegerField(default=0)
    fuel_type = models.CharField(max_length=16, choices=FUEL_CHOICES, default="petrol")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.make} {self.model}"


class MaintenanceRecord(models.Model):
    CATEGORY_CHOICES = [
        ("oil", "تعویض روغن"),
        ("filter", "فیلتر"),
        ("brakes", "ترمز"),
        ("tires", "لاستیک"),
        ("battery", "باتری"),
        ("inspection", "بازبینی"),
        ("repair", "تعمیر"),
        ("other", "سایر"),
    ]
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name="maintenance_records")
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default="other")
    title = models.CharField(max_length=160)
    service_date = models.DateField()
    odometer_km = models.PositiveIntegerField(null=True, blank=True)
    cost = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    currency = models.CharField(max_length=8, default="IRR")
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-service_date", "-id"]


class Expense(models.Model):
    CATEGORY_CHOICES = [
        ("fuel", "سوخت"),
        ("repair", "تعمیرات"),
        ("maintenance", "سرویس"),
        ("insurance", "بیمه"),
        ("tax", "عوارض"),
        ("parking", "پارکینگ"),
        ("wash", "کارواش"),
        ("other", "سایر"),
    ]
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name="expenses")
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default="other")
    title = models.CharField(max_length=160)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=8, default="IRR")
    expense_date = models.DateField()
    odometer_km = models.PositiveIntegerField(null=True, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-expense_date", "-id"]
