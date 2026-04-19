const pool = require('../config/database');

// ─── Nepal Tax Calculation (FY 2081/82) ───────────────────────────────────────
// Annual income tax slabs (individual - single)
// 0 - 500,000       → 1% (social security tax)
// 500,001 - 700,000 → 10%
// 700,001 - 1,000,000 → 20%
// 1,000,001 - 2,000,000 → 30%
// Above 2,000,000   → 36%
// Couple gets NPR 50,000 extra exemption

function calculateIncomeTax(annualTaxableIncome, exemptionType = 'single') {
  const exemption = exemptionType === 'couple' ? 550000 : 500000;
  const taxable = Math.max(0, annualTaxableIncome - exemption);

  let tax = 0;

  if (taxable <= 0) {
    tax = annualTaxableIncome * 0.01; // 1% social security on income below exemption
  } else {
    // 1% on first exemption amount
    tax += exemption * 0.01;

    const slab1 = 200000; // 500k-700k
    const slab2 = 300000; // 700k-1M
    const slab3 = 1000000; // 1M-2M

    let remaining = taxable;

    if (remaining > 0) {
      const s1 = Math.min(remaining, slab1);
      tax += s1 * 0.10;
      remaining -= s1;
    }
    if (remaining > 0) {
      const s2 = Math.min(remaining, slab2);
      tax += s2 * 0.20;
      remaining -= s2;
    }
    if (remaining > 0) {
      const s3 = Math.min(remaining, slab3);
      tax += s3 * 0.30;
      remaining -= s3;
    }
    if (remaining > 0) {
      tax += remaining * 0.36;
    }
  }

  return Math.round(tax / 12); // Monthly tax
}

// SSF: Employee 11% of basic, Employer 20% of basic (Nepal SSF Act 2074)
function calculateSSF(basicSalary) {
  return {
    employee: Math.round(basicSalary * 0.11),
    employer: Math.round(basicSalary * 0.20),
  };
}

// ─── Get salary structure of an employee ─────────────────────────────────────
const getSalaryStructure = async (req, res) => {
  try {
    const employeeId = req.params.employeeId || req.user.id;

    // Only admin/manager can view others' salary
    if (parseInt(employeeId) !== req.user.id && req.user.role === 'employee') {
      return res.status(403).json({ error: 'Access denied' });
    }

    const result = await pool.query(
      `SELECT ss.*, e.full_name, e.employee_code, e.department, e.position
       FROM salary_structures ss
       JOIN employees e ON e.id = ss.employee_id
       WHERE ss.employee_id = $1`,
      [employeeId]
    );

    if (result.rows.length === 0) {
      // Return basic salary from employees table as fallback
      const emp = await pool.query(
        'SELECT id, full_name, employee_code, basic_salary FROM employees WHERE id = $1',
        [employeeId]
      );
      if (emp.rows.length === 0) return res.status(404).json({ error: 'Employee not found' });

      return res.json({
        employee_id: emp.rows[0].id,
        full_name: emp.rows[0].full_name,
        employee_code: emp.rows[0].employee_code,
        basic_salary: parseFloat(emp.rows[0].basic_salary) || 0,
        housing_allowance: 0,
        transport_allowance: 0,
        medical_allowance: 0,
        other_allowance: 0,
        ssf_rate: 11,
        cit_amount: 0,
        tax_exemption_type: 'single',
        is_default: true,
      });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Get salary structure error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ─── Create or Update salary structure (Admin only) ──────────────────────────
const upsertSalaryStructure = async (req, res) => {
  try {
    const {
      employee_id,
      basic_salary,
      housing_allowance = 0,
      transport_allowance = 0,
      medical_allowance = 0,
      other_allowance = 0,
      cit_amount = 0,
      tax_exemption_type = 'single',
    } = req.body;

    if (!employee_id || !basic_salary) {
      return res.status(400).json({ error: 'employee_id and basic_salary are required' });
    }

    const result = await pool.query(
      `INSERT INTO salary_structures
         (employee_id, basic_salary, housing_allowance, transport_allowance,
          medical_allowance, other_allowance, cit_amount, tax_exemption_type, effective_from)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,CURRENT_DATE)
       ON CONFLICT (employee_id) DO UPDATE SET
         basic_salary = EXCLUDED.basic_salary,
         housing_allowance = EXCLUDED.housing_allowance,
         transport_allowance = EXCLUDED.transport_allowance,
         medical_allowance = EXCLUDED.medical_allowance,
         other_allowance = EXCLUDED.other_allowance,
         cit_amount = EXCLUDED.cit_amount,
         tax_exemption_type = EXCLUDED.tax_exemption_type,
         updated_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [employee_id, basic_salary, housing_allowance, transport_allowance,
       medical_allowance, other_allowance, cit_amount, tax_exemption_type]
    );

    // Also update basic_salary in employees table
    await pool.query('UPDATE employees SET basic_salary = $1 WHERE id = $2', [basic_salary, employee_id]);

    res.json({ message: 'Salary structure saved', data: result.rows[0] });
  } catch (error) {
    console.error('Upsert salary structure error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ─── Generate payroll for an employee for a given month ──────────────────────
const generatePayroll = async (req, res) => {
  try {
    const { employee_id, month_year } = req.body;
    // month_year format: "2025-01" → stored as "2025-01-01"

    if (!employee_id || !month_year) {
      return res.status(400).json({ error: 'employee_id and month_year (YYYY-MM) required' });
    }

    const monthDate = `${month_year}-01`;

    // Check if already generated
    const existing = await pool.query(
      'SELECT id, payment_status FROM payroll_records WHERE employee_id = $1 AND month = $2',
      [employee_id, monthDate]
    );
    if (existing.rows.length > 0 && existing.rows[0].payment_status === 'paid') {
      return res.status(400).json({ error: 'Payroll already paid for this month' });
    }

    // Get salary structure
    let ss = await pool.query(
      'SELECT * FROM salary_structures WHERE employee_id = $1',
      [employee_id]
    );

    let basicSalary, housingAllowance, transportAllowance, medicalAllowance,
        otherAllowance, citAmount, taxExemptionType;

    if (ss.rows.length === 0) {
      // Fallback to employees table
      const emp = await pool.query('SELECT basic_salary FROM employees WHERE id = $1', [employee_id]);
      if (emp.rows.length === 0) return res.status(404).json({ error: 'Employee not found' });
      basicSalary = parseFloat(emp.rows[0].basic_salary) || 0;
      housingAllowance = 0; transportAllowance = 0; medicalAllowance = 0;
      otherAllowance = 0; citAmount = 0; taxExemptionType = 'single';
    } else {
      const s = ss.rows[0];
      basicSalary = parseFloat(s.basic_salary);
      housingAllowance = parseFloat(s.housing_allowance);
      transportAllowance = parseFloat(s.transport_allowance);
      medicalAllowance = parseFloat(s.medical_allowance);
      otherAllowance = parseFloat(s.other_allowance);
      citAmount = parseFloat(s.cit_amount);
      taxExemptionType = s.tax_exemption_type;
    }

    const totalAllowances = housingAllowance + transportAllowance + medicalAllowance + otherAllowance;
    const grossSalary = basicSalary + totalAllowances;

    // SSF calculation (11% employee, 20% employer on basic)
    const ssf = calculateSSF(basicSalary);
    const ssfEmployee = ssf.employee;
    const ssfEmployer = ssf.employer;

    // Annual taxable = (gross - SSF employee - CIT) * 12
    const monthlyTaxable = grossSalary - ssfEmployee - citAmount;
    const annualTaxable = monthlyTaxable * 12;
    const monthlyTax = calculateIncomeTax(annualTaxable, taxExemptionType);

    const totalDeductions = ssfEmployee + monthlyTax + citAmount;
    const netSalary = grossSalary - totalDeductions;

    // Upsert payroll record
    const result = await pool.query(
      `INSERT INTO payroll_records
         (employee_id, month, basic_salary, allowances, pf_employee, pf_employer,
          income_tax, other_deductions, net_salary, payment_status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,'pending')
       ON CONFLICT (employee_id, month) DO UPDATE SET
         basic_salary = EXCLUDED.basic_salary,
         allowances = EXCLUDED.allowances,
         pf_employee = EXCLUDED.pf_employee,
         pf_employer = EXCLUDED.pf_employer,
         income_tax = EXCLUDED.income_tax,
         other_deductions = EXCLUDED.other_deductions,
         net_salary = EXCLUDED.net_salary
       RETURNING *`,
      [employee_id, monthDate, basicSalary, totalAllowances,
       ssfEmployee, ssfEmployer, monthlyTax, citAmount, netSalary]
    );

    res.json({
      message: 'Payroll generated successfully',
      data: {
        ...result.rows[0],
        breakdown: {
          gross_salary: grossSalary,
          housing_allowance: housingAllowance,
          transport_allowance: transportAllowance,
          medical_allowance: medicalAllowance,
          other_allowance: otherAllowance,
          ssf_employee: ssfEmployee,
          ssf_employer: ssfEmployer,
          cit: citAmount,
          income_tax: monthlyTax,
          net_salary: netSalary,
        },
      },
    });
  } catch (error) {
    console.error('Generate payroll error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ─── Get my payslips (employee) ───────────────────────────────────────────────
const getMyPayslips = async (req, res) => {
  try {
    const employeeId = req.user.id;

    const result = await pool.query(
      `SELECT pr.*, e.full_name, e.employee_code, e.position, e.department
       FROM payroll_records pr
       JOIN employees e ON e.id = pr.employee_id
       WHERE pr.employee_id = $1
       ORDER BY pr.month DESC
       LIMIT 12`,
      [employeeId]
    );

    res.json({ data: result.rows });
  } catch (error) {
    console.error('Get payslips error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ─── Get single payslip with breakdown ───────────────────────────────────────
const getPayslipDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const result = await pool.query(
      `SELECT pr.*, e.full_name, e.employee_code, e.position, e.department,
              e.join_date, e.phone, e.email,
              ss.housing_allowance, ss.transport_allowance,
              ss.medical_allowance, ss.other_allowance, ss.cit_amount
       FROM payroll_records pr
       JOIN employees e ON e.id = pr.employee_id
       LEFT JOIN salary_structures ss ON ss.employee_id = pr.employee_id
       WHERE pr.id = $1`,
      [id]
    );

    if (result.rows.length === 0) return res.status(404).json({ error: 'Payslip not found' });

    const payslip = result.rows[0];

    // Employees can only see their own payslips
    if (req.user.role === 'employee' && payslip.employee_id !== userId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    res.json({ data: payslip });
  } catch (error) {
    console.error('Get payslip detail error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ─── Get all payrolls for a month (Admin/Manager) ─────────────────────────────
const getAllPayrolls = async (req, res) => {
  try {
    const { month_year, status } = req.query;
    let query = `
      SELECT pr.*, e.full_name, e.employee_code, e.department, e.position
      FROM payroll_records pr
      JOIN employees e ON e.id = pr.employee_id
      WHERE 1=1
    `;
    const params = [];

    if (month_year) {
      params.push(`${month_year}-01`);
      query += ` AND pr.month = $${params.length}`;
    }
    if (status) {
      params.push(status);
      query += ` AND pr.payment_status = $${params.length}`;
    }

    query += ' ORDER BY e.full_name ASC';

    const result = await pool.query(query, params);
    res.json({ data: result.rows });
  } catch (error) {
    console.error('Get all payrolls error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ─── Mark payroll as paid ─────────────────────────────────────────────────────
const markAsPaid = async (req, res) => {
  try {
    const { id } = req.params;
    const { payment_method = 'bank_transfer', remarks } = req.body;

    const result = await pool.query(
      `UPDATE payroll_records
       SET payment_status = 'paid', payment_date = CURRENT_DATE,
           payment_method = $1, remarks = $2
       WHERE id = $3
       RETURNING *`,
      [payment_method, remarks, id]
    );

    if (result.rows.length === 0) return res.status(404).json({ error: 'Payroll not found' });

    res.json({ message: 'Marked as paid', data: result.rows[0] });
  } catch (error) {
    console.error('Mark paid error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ─── Generate bulk payroll for all employees ──────────────────────────────────
const generateBulkPayroll = async (req, res) => {
  try {
    const { month_year } = req.body;
    if (!month_year) return res.status(400).json({ error: 'month_year required' });

    const employees = await pool.query(
      "SELECT id FROM employees WHERE status = 'active'"
    );

    const results = { success: [], failed: [] };

    for (const emp of employees.rows) {
      try {
        // Reuse logic inline
        const monthDate = `${month_year}-01`;
        const existing = await pool.query(
          'SELECT id, payment_status FROM payroll_records WHERE employee_id = $1 AND month = $2',
          [emp.id, monthDate]
        );
        if (existing.rows.length > 0 && existing.rows[0].payment_status === 'paid') {
          results.failed.push({ id: emp.id, reason: 'Already paid' });
          continue;
        }

        let ss = await pool.query('SELECT * FROM salary_structures WHERE employee_id = $1', [emp.id]);
        let basicSalary, totalAllowances, citAmount, taxExemptionType;

        if (ss.rows.length === 0) {
          const e = await pool.query('SELECT basic_salary FROM employees WHERE id = $1', [emp.id]);
          basicSalary = parseFloat(e.rows[0]?.basic_salary) || 0;
          totalAllowances = 0; citAmount = 0; taxExemptionType = 'single';
        } else {
          const s = ss.rows[0];
          basicSalary = parseFloat(s.basic_salary);
          totalAllowances = parseFloat(s.housing_allowance) + parseFloat(s.transport_allowance) +
                            parseFloat(s.medical_allowance) + parseFloat(s.other_allowance);
          citAmount = parseFloat(s.cit_amount);
          taxExemptionType = s.tax_exemption_type;
        }

        const grossSalary = basicSalary + totalAllowances;
        const ssf = calculateSSF(basicSalary);
        const monthlyTax = calculateIncomeTax((grossSalary - ssf.employee - citAmount) * 12, taxExemptionType);
        const netSalary = grossSalary - ssf.employee - monthlyTax - citAmount;

        await pool.query(
          `INSERT INTO payroll_records
             (employee_id, month, basic_salary, allowances, pf_employee, pf_employer,
              income_tax, other_deductions, net_salary, payment_status)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,'pending')
           ON CONFLICT (employee_id, month) DO UPDATE SET
             basic_salary = EXCLUDED.basic_salary, allowances = EXCLUDED.allowances,
             pf_employee = EXCLUDED.pf_employee, pf_employer = EXCLUDED.pf_employer,
             income_tax = EXCLUDED.income_tax, other_deductions = EXCLUDED.other_deductions,
             net_salary = EXCLUDED.net_salary`,
          [emp.id, monthDate, basicSalary, totalAllowances, ssf.employee, ssf.employer, monthlyTax, citAmount, netSalary]
        );

        results.success.push(emp.id);
      } catch (e) {
        results.failed.push({ id: emp.id, reason: e.message });
      }
    }

    res.json({
      message: `Bulk payroll done. Success: ${results.success.length}, Failed: ${results.failed.length}`,
      results,
    });
  } catch (error) {
    console.error('Bulk payroll error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

module.exports = {
  getSalaryStructure,
  upsertSalaryStructure,
  generatePayroll,
  getMyPayslips,
  getPayslipDetail,
  getAllPayrolls,
  markAsPaid,
  generateBulkPayroll,
};