export default function ChartCard({ title, children }) {
  return (
    <div className="bg-white rounded-2xl shadow-md p-5">
      <h3 className="text-primary font-bold text-lg mb-4">{title}</h3>
      {children}
    </div>
  );
}
