from rest_framework import viewsets
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from .models import Vehicle, MaintenanceRecord, Expense
from .serializers import VehicleSerializer, MaintenanceRecordSerializer, ExpenseSerializer


@api_view(["GET"])
@permission_classes([AllowAny])
def health(request):
    return Response({"status": "ok", "service": "dastyar-khodro-api", "version": "0.1.0"})


class VehicleViewSet(viewsets.ModelViewSet):
    serializer_class = VehicleSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Vehicle.objects.filter(owner=self.request.user)

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class OwnedVehicleRecordsMixin:
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return self.model.objects.filter(vehicle__owner=self.request.user)

    def _assert_vehicle_owner(self, vehicle):
        if vehicle.owner_id != self.request.user.id:
            raise PermissionDenied("این خودرو متعلق به حساب شما نیست.")

    def perform_create(self, serializer):
        self._assert_vehicle_owner(serializer.validated_data["vehicle"])
        serializer.save()

    def perform_update(self, serializer):
        vehicle = serializer.validated_data.get("vehicle", serializer.instance.vehicle)
        self._assert_vehicle_owner(vehicle)
        serializer.save()


class MaintenanceRecordViewSet(OwnedVehicleRecordsMixin, viewsets.ModelViewSet):
    model = MaintenanceRecord
    serializer_class = MaintenanceRecordSerializer


class ExpenseViewSet(OwnedVehicleRecordsMixin, viewsets.ModelViewSet):
    model = Expense
    serializer_class = ExpenseSerializer
