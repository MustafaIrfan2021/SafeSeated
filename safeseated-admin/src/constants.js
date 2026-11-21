// Documents each account type must have approved before verification
export const DOCS = {
  drivers: {
    cnicFront: 'CNIC front',
    cnicBack: 'CNIC back',
    drivingLicence: 'Driving licence',
    vehicleRegistration: 'Vehicle registration',
    vehiclePhoto: 'Vehicle photo',
  },
  passengers: {
    cnicFront: 'CNIC front',
    cnicBack: 'CNIC back',
    studentCard: 'Student card',
  },
};
export const STATUSES = ['Pending Review', 'Under Review', 'Approved', 'Rejected', 'Resubmission Required', 'Suspended'];
export const money = n => 'Rs. ' + Number(n || 0).toLocaleString('en-US');
export const sum = (a, f) => a.reduce((s, x) => s + f(x), 0);
