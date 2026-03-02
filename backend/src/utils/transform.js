/**
 * Transform object keys from snake_case to camelCase
 */
const toCamelCase = (obj) => {
  if (obj === null || obj === undefined) return obj;
  if (Array.isArray(obj)) return obj.map(toCamelCase);
  if (typeof obj !== 'object') return obj;

  const result = {};
  for (const key in obj) {
    const camelKey = key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
    const value = obj[key];
    result[camelKey] = (value !== null && typeof value === 'object' && !Array.isArray(value))
      ? toCamelCase(value)
      : value;
  }
  return result;
};

/**
 * Transform single item
 */
const transformItem = (item) => toCamelCase(item);

/**
 * Transform array of items
 */
const transformArray = (items) => items.map(toCamelCase);

/**
 * Transform response with data
 */
const transformResponse = (data) => {
  if (Array.isArray(data)) {
    return transformArray(data);
  }
  return transformItem(data);
};

/**
 * Transform parking zone (handles special cases)
 */
const transformZone = (zone) => {
  if (!zone) return zone;
  return toCamelCase(zone);
};

/**
 * Transform user object
 */
const transformUser = (user) => {
  if (!user) return user;
  return toCamelCase(user);
};

/**
 * Transform report object
 */
const transformReport = (report) => {
  if (!report) return report;
  return toCamelCase(report);
};

module.exports = {
  toCamelCase,
  transformItem,
  transformArray,
  transformResponse,
  transformZone,
  transformUser,
  transformReport
};
